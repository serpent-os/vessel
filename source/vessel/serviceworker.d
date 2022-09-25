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
    this(VesselEventQueue queue, string rootDir) @safe
    {
        this.queue = queue;
        this.rootDir = rootDir;
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
     * Perform an import into the volatile branch
     *
     * Params:
     *      event = The event
     */
    void importStones(ImportStonesEvent event) @safe
    {
        logInfo(format!"Import request for: %s"(event));
    }

    string rootDir = ".";
    bool running;
    VesselEventQueue queue;
}
