/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.serviceworker
 *
 * Handles the whole "run forever and fetch things" routine.
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module vessel.serviceworker;

import vibe.d;
import moss.fetcher;
import moss.deps.registry.job;
import std.path : buildPath, baseName;
import moss.core.util : computeSHA256;
import std.algorithm : filter;

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
    this(VesselEventQueue queue, string rootDir) @safe
    {
        this.queue = queue;
        this.rootDir = rootDir;
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

        VesselEvent event;
        while (queue.tryConsumeOne(event))
        {
            final switch (event.kind)
            {
            case VesselEvent.Kind.importStones:
                importStones(event.get!(VesselEvent.Kind.importStones));
                break;
            }
        }
        logInfo("ServiceWorker no longer running");
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
                logError(format!"%s: Expected hash %s, got %s"(f.sourceURI, expHash, compHash));
                job.status = JobStatus.Failed;
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

        immutable failedJobs = jobs.values.filter!((j) => j.status == JobStatus.Failed);
        if (!failedJobs.empty)
        {
            logError(format!"Cannot accept job due to failure");
            return;
        }

        logInfo("Successfully importing job");
    }

    void onProgress(uint workerIndex, Fetchable f, double dlCurrent, double dlTotal) @trusted
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
    }

    string rootDir = ".";
    string stagingDir;
    bool running;
    VesselEventQueue queue;
    FetchController fetcher;
    Job[string] jobs;
}
