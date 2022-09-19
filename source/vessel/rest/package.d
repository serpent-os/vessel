/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**

moss collection add official https://collections.serpentos.com/%(arch)/branches/current/%(format)/stone.index


x86_64/
    branches/
        volatile
            stone.index
        current
            1/
                stone.index -> ../../releases/2022..../stone.index
        testing
            1/
                stone.index -> ../../releases/2022..../stone.index

    pool/
        n/nano/
            *.stone
    releases/
        2022..../stone.index

collection/ scanning:

    pkgIDs = []
    foreach pkg in find . -name manifest*.bin;
        if pkg.mossVersion > highestMossVersion
            highestMossVersion = pkg.mossVersion
        pkgIDs ~= pkg.id

    release = Release()
    release.formatVersion = highestMossVersion
    release.pkgIDs = pkgIDs

    [git branch testing]
        push tag

    [git branch main (current)]

// Simple index format
moss collection add official https://collection.serpentos.com/current/1/stone.index
moss collection add testing https://collection.serpentos.com/testing/2/stone.index
moss collection add volatile https://collection.serpentos.com/volatile/stone.index

moss collection add <noun> url/

UNLESS collection ends with "stone.index", automatically add:

    mossFormatVersion/stone.index













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
     * Typically the pkgID
     */
    string id;

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
    @method(HTTPMethod.POST) @path("collections/import/") void importBinaries(
            uint64_t reportID, Collectable[] collectables) @safe;
}

/**
 * Concrete implementation of the interface
 */
public final class VesselAPI : VesselAPIv1
{

    override void importBinaries(uint64_t reportID,
            Collectable[] collectables) @safe
    {
    }
}
