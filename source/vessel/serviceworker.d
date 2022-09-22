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
    this(string rootDir, Tid mainApp) @safe
    {
        this.rootDir = rootDir;
        this.mainApp = mainApp;

        /* Configure the mailbox for a backlog */
        () @trusted { setMaxMailboxSize(thisTid, 0, OnCrowding.block); }();
    }

    /**
     * Serve the collection requests
     */
    void serve()
    {
        logInfo("ServiceWorker now servicing requests");
        () @trusted { register("serviceWorker", thisTid()); }();

        running = true;

        send(mainApp, WorkerStarted(thisTid));

        while (running)
        {
            receive((StopServing _) { running = false; }, (ImportStones req) {
                this.importStones(req);
            });
        }
        logInfo("ServiceWorker no longer running");
    }

private:

    /**
     * Perform an import into the volatile branch
     *
     * Params:
     *      req = The request
     */
    void importStones(ImportStones req) @safe
    {
        logInfo(format!"Import request for: %s"(req));
    }

    string rootDir = ".";
    bool running;
    Tid mainApp;
}
