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
import vibe.d;
import vessel.models;
import std.path : buildPath;
import std.array : array;

/**
 * Known state for failure handling
 */
public alias CollectionResult = Optional!(Success, Failure);

/**
 * Either a record or nada.
 */
public alias VolatileResult = Optional!(VolatileRecord, Failure);

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
        immutable dbPath = rootDir.buildPath("db", "collection");
        immutable driverString = format!"lmdb://%s"(dbPath);
        logTrace(format!"CollectionDB: %s"(dbPath));
        immutable flags = DatabaseFlags.CreateIfNotExists;

        return Database.open(driverString, flags).match!((Database db) {
            this.db = db;
            immutable err = db.update((scope tx) => tx.createModel!(VolatileRecord));
            return err.isNull
                ? cast(CollectionResult) Success() : cast(CollectionResult) fail(err.message);
        }, (DatabaseError err) { return cast(CollectionResult) fail(err.toString); });
    }

    /**
     * Lookup a record by *name*
     *
     * Params:
     *      name = Package name (provider)
     * Returns: Either a record, or a failure
     */
    VolatileResult lookupVolatile(string name) @safe
    in
    {
        assert(name !is null);
    }
    do
    {
        VolatileRecord record;
        immutable err = db.view((in tx) => record.load(tx, name));
        return err.isNull ? cast(VolatileResult) record : cast(VolatileResult) fail(err.message);
    }

    /**
     * Store the updated volatile record
     *
     * Params:
     *      record = New record to store.
     * Returns: Success or failure
     */
    CollectionResult storeVolatile(scope const ref VolatileRecord record) @safe
    in
    {
        assert(record.name !is null);
        assert(record.pkgID !is null);
    }
    do
    {
        immutable err = db.update((scope tx) => record.save(tx));
        return err.isNull ? cast(CollectionResult) Success() : cast(
                CollectionResult) fail(err.message);
    }

    /**
     * Close underlying storage
     */
    void close() @safe
    {
        if (db is null)
        {
            return;
        }
        db.close();
        db = null;
    }

    /**
     * Return all volatile records (unsorted)
     *
     * Returns: All volatile entries
     */
    auto volatileRecords() @safe
    {
        VolatileRecord[] records;

        db.view((in tx) @trusted {
            records = tx.list!VolatileRecord.array;
            return NoDatabaseError;
        });

        return records;
    }

private:

    string rootDir = ".";
    Database db;
}
