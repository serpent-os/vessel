/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.indexer
 *
 * Emits index files for the collection
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.indexer;

import moss.client.metadb;
import moss.format.binary.archive_header;
import moss.format.binary.payload;
import moss.format.binary.payload.meta;
import moss.format.binary.writer;
import std.algorithm : multiSort;
import std.file : exists, mkdirRecurse;
import std.path : buildPath, dirName, relativePath;
import vessel.collectiondb;
import vibe.d;

/**
 * The Indexer is responsible for collating entries from the
 * MetaDB, keyed by the CollectionDB
 */
public final class Indexer
{
    @disable this();

    /**
     * Construct a new Indexer
     *
     * Params:
     *      outputFilename = Where to write the index file
     */
    this(string rootDir, string outputFilename) @safe
    {
        this.rootDir = rootDir;
        this.outputFilename = outputFilename;
    }

    /**
     * Write the index file out using the given collection + metadb backing store
     * NOTE: Only supports volatile right now.
     *
     * Params:
     *      collectionDB = Populated collection DB
     *      metaDB       = Populated metadata DB
     */
    void index(scope CollectionDB collectionDB, scope MetaDB metaDB) @safe
    {
        immutable outputDirectory = outputFilename.dirName;
        if (!outputDirectory.exists)
        {
            outputDirectory.mkdirRecurse();
        }

        auto records = collectionDB.volatileRecords();
        records.multiSort!((a, b) => a.sourceID < b.sourceID, (a, b) => a.name < b.name);
        auto fi = File(outputFilename, "wb");
        auto wr = new Writer(fi);
        wr.fileType = MossFileType.Repository;
        wr.compressionType = PayloadCompression.Zstd;
        foreach (record; records)
        {
            MetaEntry ent = metaDB.byID(record.pkgID);
            auto mp = new MetaPayload();
            () @trusted {
                mp.addRecord(RecordType.String, RecordTag.Architecture, ent.architecture);
                mp.addRecord(RecordType.String, RecordTag.Description, ent.description);
                mp.addRecord(RecordType.String, RecordTag.Homepage, ent.homepage);
                mp.addRecord(RecordType.String, RecordTag.Name, ent.name);
                mp.addRecord(RecordType.String, RecordTag.SourceID, ent.sourceID);
                mp.addRecord(RecordType.String, RecordTag.Summary, ent.summary);
                mp.addRecord(RecordType.String, RecordTag.Version, ent.versionIdentifier);
                mp.addRecord(RecordType.Uint64, RecordTag.BuildRelease, ent.buildRelease);
                mp.addRecord(RecordType.Uint64, RecordTag.Release, ent.sourceRelease);
                foreach (lic; ent.licenses)
                {
                    mp.addRecord(RecordType.String, RecordTag.License, lic);
                }
                foreach (dep; ent.dependencies)
                {
                    mp.addRecord(RecordType.Dependency, RecordTag.Depends, dep);
                }
                foreach (prov; ent.providers)
                {
                    mp.addRecord(RecordType.Provider, RecordTag.Provides, prov);
                }
                /* Need a relative path due to branch work */
                immutable fullPath = rootDir.buildPath(ent.uri);
                mp.addRecord(RecordType.String, RecordTag.PackageURI,
                        fullPath.relativePath(outputDirectory));
                mp.addRecord(RecordType.String, RecordTag.PackageHash, ent.hash);
                mp.addRecord(RecordType.Uint64, RecordTag.PackageSize, ent.downloadSize);
            }();
            wr.addPayload(mp);
        }
        wr.close();
    }

private:

    string outputFilename;
    string rootDir;
}
