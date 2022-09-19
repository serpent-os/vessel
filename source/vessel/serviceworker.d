/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.serviceworker
 *
 * Control thread for incoming ops
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module vessel.serviceworker;

import vibe.d;

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
    this(string rootDir) @safe
    {
        this.rootDir = rootDir;
    }

    /**
     * Serve the collection requests
     */
    void serve()
    {
        logInfo("ServiceWorker now servicing requests");
        () @trusted { register("serviceWorker", thisTid()); }();

        running = true;

        while (running)
        {
            receive((StopServing _) { running = false; });
        }
        logInfo("ServiceWorker no longer running");
    }

private:

    string rootDir = ".";
    bool running;
}
