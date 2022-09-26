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

import vibe.d;
import vessel.collectiondb;
import moss.client.metadb;
import moss.format.binary.writer;

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
    this(string outputFilename) @safe
    {
        this.outputFilename = outputFilename;
    }

    /**
     * Write the index file out using the given collection + metadb backing store
     *
     * Params:
     *      collectionDB = Populated collection DB
     *      metaDB       = Populated metadata DB
     */
    void index(scope CollectionDB collectionDB, scope MetaDB metaDB) @safe
    {

    }

private:

    string outputFilename;
}
