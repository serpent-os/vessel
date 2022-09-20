/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.rest
 *
 * REST API for Vessel
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.rest;

import vibe.d;
import std.stdint : uint64_t;
import vessel.messaging;
import std.exception : assumeUnique;

/**
 * We only care for packages right now.
 */
public enum CollectableType : string
{
    Log = "log",
    Manifest = "manifest",
    Package = "package",
}

/**
 * A Collectable is essentially just a .stone with a hash
 */
public struct Collectable
{
    /**
     * Type of collectable
     */
    CollectableType type;

    /**
     * Where can we download this from?
     */
    string uri;

    /**
     * Similarly, what is the hash?
     */
    string sha256sum;
}

/**
 * Contract for our API
 */
@path("/api/v1")
public interface VesselAPIv1
{
    /**
     * Request an import of binaries into the volatile branch
     *
     * Params:
     *      reportID     = ID to use when reporting back on status
     *      collectables = The stones to collect
     */
    @method(HTTPMethod.POST) @path("collections/import") void importBinaries(
            uint64_t reportID, Collectable[] collectables) @safe;
}

/**
 * Concrete implementation of the interface
 */
public final class VesselAPI : VesselAPIv1
{
    @disable this();

    /**
     * Construct VesselAPI implementation with knowledge of the worker
     */
    this(Tid workerTid) @safe
    {
        this.workerTid = workerTid;
    }

    override void importBinaries(uint64_t reportID, Collectable[] collectables) @safe
    {
        string[] uris;
        string[] hashes;
        foreach (col; collectables)
        {
            if (col.type != CollectableType.Package)
            {
                continue;
            }
            hashes ~= col.sha256sum;
            uris ~= col.uri;
        }
        () @trusted {
            send(workerTid, ImportStones(assumeUnique(uris), assumeUnique(hashes)));
        }();
    }

private:

    Tid workerTid;
}
