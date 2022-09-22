/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.servicecontroller
 *
 * Control thread for incoming ops
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module vessel.servicecontroller;

import vibe.d;

public import vessel.messaging;

/**
 * The ServiceController is the meat and bones of vessel
 */
public final class ServiceController
{

    @disable this();

    /**
     * Construct a new ServiceController
     */
    this(string rootDir, Tid mainApp) @safe
    {
        this.rootDir = rootDir;
        this.mainApp = mainApp;

        /* Configure the mailbox for a backlog */
        () @trusted { setMaxMailboxSize(thisTid, 0, OnCrowding.block); }();
    }

    /**
     * Begin serving
     */
    public void serve()
    {
        logInfo("ServiceController now servicing requests");
        () @trusted { register("serviceController", thisTid()); }();

        /* Notify main app we're up and running now */
        send(mainApp, ControllerStarted(thisTid));

        running = true;
        while (running)
        {
            receive((StopServing _) { running = false; });
        }
        logInfo("ServiceController no longer running");
    }

private:

    string rootDir = ".";
    Tid mainApp;
    bool running;
}
