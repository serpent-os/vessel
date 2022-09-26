/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.collectiondb
 *
 * Collection DB
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.collectiondb;

public import moss.core.errors;
import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.orm;

/**
 * Known state for failure handling
 */
public alias CollectionResult = Optional!(Success, Failure);

/**
 * The CollectionDB manages the storage of pointer records within
 * branch releases. Additionally it handles the special case Volatile
 * branch, from which all branches are cut.
 *
 * Consider volatile a pool of *potentials* in trunk form, and reach
 * release cut from a known state, immutable in time.
 */
public final class CollectionDB
{
    @disable this();

    /**
     * Construct a new CollectionDB using the given root directory
     */
    this(string rootDir) @safe
    {
        this.rootDir = rootDir;
    }

    /**
     * Connect to the underlying storage
     *
     * Returns: Optional result type
     */
    CollectionResult connect() @safe
    {
        return cast(CollectionResult) fail("Not yet implemented");
    }

    /**
     * Close underlying storage
     */
    void close() @safe
    {

    }

private:

    string rootDir = ".";
}
