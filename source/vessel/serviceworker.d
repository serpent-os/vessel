/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.serviceworker
 *
 * Handles the whole "run forever and fetch things" routine.
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */
module vessel.serviceworker;

import moss.client.metadb;
import moss.core.errors;
import moss.core.util : computeSHA256;
import moss.deps.registry.job;
import moss.fetcher;
import moss.format.binary.payload.meta;
import moss.format.binary.reader;
import std.algorithm : filter, map, sort;
import std.array : array;
import std.file : mkdirRecurse, rename, dirEntries, SpanMode;
import std.range : chunks;
import std.path : baseName, buildPath, dirName;
import std.stdio : File;
import vessel.collectiondb;
import vessel.indexer;
import vibe.d;
import vessel.models;

public import vessel.messaging;

/**
 * We refer to trunk as "volatile"
 */
public static immutable(string) trunkBranch = "volatile";

/**
 * ServiceWorker is the writer queue for the underlying databases
 * and ensures correct import procedures for stones
 */
public final class ServiceWorker
{

    @disable this();

    /**
     * Construct a new ServiceWorker
     */
    this(VesselEventQueue queue, ReportEventQueue reportQueue, string rootDir) @safe
    {
        this.queue = queue;
        this.reportQueue = reportQueue;
        this.rootDir = rootDir;
        this.collectionDB = new CollectionDB(rootDir);
        /* Use all the threads. Crack on my man */
        fetcher = new FetchController();
        fetcher.onProgress.connect(&onProgress);
        fetcher.onComplete.connect(&onComplete);
        fetcher.onFail.connect(&onFail);

        stagingDir = rootDir.buildPath("staging");
    }

    /**
     * Serve the collection requests
     */
    void serve() @safe
    {
        logInfo("ServiceWorker now servicing requests");

        db = new MetaDB(rootDir.buildPath("db", "meta"), true);
        db.connect.match!((Success _) {}, (Failure f) {
            throw new Exception(f.message);
        });

        collectionDB = new CollectionDB(rootDir);
        collectionDB.connect.match!((Success _) {}, (Failure f) {
            throw new Exception(f.message);
        });

        VesselEvent event;
        while (queue.tryConsumeOne(event))
        {
            final switch (event.kind)
            {
            case VesselEvent.Kind.importStones:
                importStones(cast(ImportStonesEvent) event);
                break;
            case VesselEvent.Kind.importDirectory:
                /* Multiplex back into fibers */
                runTask({ importDirectory(cast(ImportDirectoryEvent) event); });
                break;
            }
        }
        logInfo("ServiceWorker no longer running");
        db.close();
        db = null;

        collectionDB.close();
        collectionDB = null;
    }

private:

    /**
     * Perform an import into the volatile branch (sequentially)
     *
     * Params:
     *      event = The event
     */
    void importStones(ImportStonesEvent event) @safe
    {
        /* Reset job storage */
        () @trusted { jobs.clear(); }();

        /**
         * This is called before the *main* completion handler.
         */
        void completionHandler(immutable(Fetchable) f, long code) @trusted
        {
            /* Let dispatch handle it */
            if (code != 0 && code != 200)
            {
                return;
            }
            auto job = jobs[f.sourceURI];
            immutable expHash = job.checksum;
            immutable compHash = computeSHA256(job.destinationPath, true);
            if (expHash != compHash)
            {
                onFail(f, format!"%s: Expected hash %s, got %s"(f.sourceURI, expHash, compHash));
                return;
            }
        }

        logInfo(format!"Import request for: %s"(event));
        foreach (i; 0 .. event.uris.length)
        {
            immutable hash = event.hashes[i];
            immutable uri = event.uris[i];
            immutable destPath = stagingDir.buildPath(hash);

            /* Key the jobs by URI. */
            auto job = new Job(JobType.FetchPackage, uri);
            job.remoteURI = uri;
            job.checksum = event.hashes[i];
            job.destinationPath = destPath;
            job.status = JobStatus.Pending;

            /* Remember it. */
            jobs[uri] = job;

            auto f = Fetchable(uri, destPath, 0, FetchType.RegularFile, &completionHandler);
            fetcher.enqueue(f);
        }

        /* Fetch all the thingies */
        while (!fetcher.empty)
        {
            fetcher.fetch();
        }

        auto failedJobs = jobs.values.filter!((j) => j.status == JobStatus.Failed);
        if (!failedJobs.empty)
        {
            foreach (failed; failedJobs)
            {
                try
                {
                    import std.file : remove;

                    failed.destinationPath.remove();
                }
                catch (Exception ex)
                {
                }
            }
            logError(format!"Cannot accept job %d due to failure"(event.reportID));
            reportQueue.put(cast(ReportEvent) ReportFailureEvent(event.reportID, event.endpoint));
            return;
        }

        /* Let's get them all included, shall we? */
        auto jobSet = jobs.values;
        bool failure;
        foreach (job; jobSet)
        {
            importFetched(job).match!((Success _) {
                logInfo(format!"Job %d: Successfully imported %s"(event.reportID, job.id));
            }, (Failure f) {
                failure = true;
                logError(format!"Job %d: Failed to import %s: %s"(event.reportID,
                    job.id, f.message));
                try
                {
                    import std.file : remove;

                    job.destinationPath.remove();
                }
                catch (Exception ex)
                {
                }
            });
        }

        reindex();

        /* Let summit know what happened */
        if (failure)
        {
            reportQueue.put(cast(ReportEvent) ReportFailureEvent(event.reportID, event.endpoint));
        }
        else
        {
            reportQueue.put(cast(ReportEvent) ReportSuccessEvent(event.reportID, event.endpoint));
        }
    }

    void onProgress(uint workerIndex, Fetchable f, double, double) @trusted
    {
        jobs[f.sourceURI].status = JobStatus.InProgress;
    }

    void onComplete(Fetchable f, long code) @trusted
    {
        if (code != 200 && code != 0)
        {
            onFail(f, format!"Status code: %s"(code));
            return;
        }
        auto job = jobs[f.sourceURI];
        if (job.status != JobStatus.InProgress)
        {
            return;
        }
        job.status = JobStatus.Completed;
    }

    void onFail(Fetchable f, string errMsg) @trusted
    {
        jobs[f.sourceURI].status = JobStatus.Failed;
        logError(errMsg);
    }

    /**
     * Import a package into the primary MetaDB
     *
     * Params:
     *      fetched = The fetched stone
     *      destructiveMove = Rename vs copy
     * Returns: A MetaResult
     */
    auto importFetched(scope Job fetched, bool destructiveMove = true) @safe
    {
        auto fi = File(fetched.destinationPath, "rb");
        scope auto rdr = new Reader(fi);
        scope (exit)
        {
            rdr.close();
        }
        if (rdr.archiveHeader.type != MossFileType.Binary)
        {
            return cast(CollectionResult) fail("Invalid archive");
        }
        VolatileRecord record;
        record.pkgID = fetched.checksum;
        string sourceID;
        string architecture;

        /* Flesh out with index metadata */
        MetaPayload mp = () @trusted {
            MetaPayload m = rdr.payload!MetaPayload;
            foreach (entry; m)
            {
                switch (entry.tag)
                {
                case RecordTag.Architecture:
                    architecture = entry.get!string;
                    break;
                case RecordTag.Name:
                    record.name = entry.get!string;
                    break;
                case RecordTag.BuildRelease:
                    record.buildRelease = entry.get!uint64_t;
                    break;
                case RecordTag.Release:
                    record.sourceRelease = entry.get!uint64_t;
                    break;
                case RecordTag.SourceID:
                    sourceID = entry.get!string;
                    break;
                default:
                    break;
                }
            }
            m.addRecord(RecordType.String, RecordTag.PackageHash,
                    cast(string) fetched.checksum.dup);
            m.addRecord(RecordType.Uint64, RecordTag.PackageSize, fi.size());
            return m;
        }();

        /* Source name *required* */
        if (sourceID.empty)
        {
            return cast(CollectionResult) fail("missing source name");
        }

        if (architecture != "x86_64")
        {
            return cast(CollectionResult) fail("serpent not yet ported to non-x86_64 targets!");
        }
        record.sourceID = sourceID;

        /* Construct the final resting place (o-O) */
        immutable poolDir = sourceNameToDir(sourceID);
        immutable targetPath = poolDir.buildPath(fetched.remoteURI().baseName);
        immutable fullPath = rootDir.buildPath(targetPath);

        /* Record the pool/ relative path */
        () @trusted {
            mp.addRecord(RecordType.String, RecordTag.PackageURI, targetPath);
        }();

        fullPath.dirName.mkdirRecurse();

        /* Check for an existing record */
        VolatileRecord existing = collectionDB.lookupVolatile(record.name)
            .match!((VolatileRecord r) => r, (_) => VolatileRecord.init);
        if (existing.sourceRelease > record.sourceRelease)
        {
            return cast(CollectionResult) fail(
                    format!"newer candidate (rel: %d) exists already"(existing.sourceRelease));
        }
        if (existing.sourceRelease == record.sourceRelease
                && record.buildRelease < existing.buildRelease)
        {
            return cast(CollectionResult) fail(
                    format!"bump release number to %s"(existing.sourceRelease + 1));
        }
        else if (existing.sourceRelease == record.sourceRelease)
        {
            return cast(CollectionResult) fail("cannot include build with identical release field");
        }

        if (destructiveMove)
        {
            fetched.destinationPath.rename(fullPath);
        }
        else
        {
            import moss.core.ioutil : IOUtil;

            () @trusted { IOUtil.copyFile(fetched.destinationPath, fullPath); }();
        }

        /* Chain install */
        return db.install(mp).match!((Success _) {
            return cast(CollectionResult) collectionDB.storeVolatile(record);
        }, (Failure f) { return cast(CollectionResult) f; });
    }

    /**
     * Import the given directory
     *
     * Params:
     *      event = Incoming event
     */
    void importDirectory(ImportDirectoryEvent event) @safe
    {
        logInfo(format!"Request to import directory: %s"(event.directory));

        auto stones = () @trusted {
            string path = event.directory;
            return path.dirEntries("*.stone", SpanMode.depth, false).map!((i) => i.name.idup).array;
        }();

        /* Every 100 packages, yield to allow work to happen */
        stones.sort!"a < b";
        ulong processed = 1;
        ulong total = stones.length;
        foreach (chunk; stones.chunks(100))
        {
            foreach (item; chunk)
            {
                immutable hash = () @trusted { return computeSHA256(item, true); }();
                scope auto job = new Job(JobType.FetchPackage, item);
                job.checksum = hash;
                job.destinationPath = item;
                job.remoteURI = format!"file://%s"(item);
                importFetched(job, false).match!((Success _) {
                    logInfo(format!"bulkImport: [%s/%s] %s"(processed, total, job.destinationPath));
                }, (Failure f) {
                    logError(format!"bulkImport: [%s/%s] fail for %s: %s"(processed,
                        total, job.destinationPath, f.message));
                });
                ++processed;

            }
            vibe.core.core.yield;
        }
        reindex();
    }

    /**
     * Handle emission of volatile
     */
    void reindex() @safe
    {
        immutable volatileIndexPath = rootDir.buildPath("public", "volatile",
                "x86_64", "stone.index");
        logInfo(format!"Indexing %s"(volatileIndexPath));
        const tsStart = Clock.currTime();
        auto idx = new Indexer(rootDir, volatileIndexPath);
        idx.index(collectionDB, db);
        const tsEnd = Clock.currTime();
        logDiagnostic(format!"Finished indexing in %s"(tsEnd - tsStart));
    }

    string rootDir = ".";
    string stagingDir;
    bool running;
    VesselEventQueue queue;
    ReportEventQueue reportQueue;
    FetchController fetcher;
    Job[string] jobs;
    MetaDB db;
    CollectionDB collectionDB;

    /**
     * Pool directory
     *
     * Params:
     *      sourceID = Source identity
     * Returns: Full pool directory
     */
    auto sourceNameToDir(string sourceID) @safe
    {
        auto nom = sourceID.toLower();
        string portion = nom[0 .. 1];
        if (sourceID.length > 4 && nom.startsWith("lib"))
        {
            portion = nom[0 .. 4];
        }
        return "public".buildPath("pool", portion, nom);
    }
}
