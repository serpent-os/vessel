/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.collection
 *
 * Collection management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module vessel.collection;

import vibe.d;

/**
 * We refer to trunk as "volatile"
 */
public static immutable(string) trunkBranch = "volatile";

public struct StopServing
{

}

/**
 * A binary collection consists of a trunk branch, referred
 * to as `volatile`, where all binary packages are imported into.
 */
public final class PackageCollection
{

    @disable this();

    /**
     * Construct a new Collection with the given root directory
     */
    this(string rootDir) @safe
    {
        this.rootDir = rootDir;
    }

    /**
     * Serve the collection requests
     */
    void serve()
    {
        logInfo("PackageCollection now servicing requests");
        () @trusted { register("collection", thisTid()); }();

        running = true;

        while (running)
        {
            receive((StopServing _) { running = false; });
        }
        logInfo("PackageCollection no longer running");
    }

private:

    string rootDir = ".";
    bool running;
}
