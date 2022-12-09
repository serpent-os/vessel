/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.app
 *
 * Main vessel application
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.app;

import moss.service.context;
import std.algorithm : filter, map;
import std.conv : to;
import std.file : exists, mkdirRecurse;
import std.path : buildPath;
import std.string : format;
import vessel.messaging;
import vessel.rest;
import vessel.serviceworker;
import vibe.d;

/**
 * Main lifecycle management for the Vessel Daemon
 */
public final class VesselApplication
{
    @disable this();

    /**
     * Construct a new VesselApplication
     */
    this(ServiceContext context) @safe
    {
        /**
         * Set up listener config
         */
        this.context = context;
        settings = new HTTPServerSettings();
        settings.bindAddresses = ["localhost",];
        settings.port = 5050;
        settings.disableDistHost = true;
        settings.serverString = "Vessel / 0.0.0";
        settings.useCompressionIfPossible = true;

        /* Primary routing mechanism for our API */
        router = new URLRouter();

        queue = createChannel!(VesselEvent, 500);
    }

    /**
     * Start the server
     */
    void start() @safe
    {
        immutable requiredDirs = [
            "public/pool", "public/releases", "public/branches", "staging",
        ];
        auto builderDirs = requiredDirs.map!((i) => context.statePath.buildPath(i))
            .filter!((i) => !i.exists);
        foreach (req; builderDirs)
        {
            logInfo(format!"Constructing tree: %s"(req));
            req.mkdirRecurse();
        }

        /* Now startup the service *worker* */
        runWorkerTask((VesselEventQueue queue, string rootDir) {
            auto c = new ServiceWorker(queue, rootDir);
            c.serve();
        }, queue, context.statePath);

        router.registerRestInterface(new VesselAPI(queue));
        router.rebuild();

        listener = listenHTTP(settings, router);
    }

    /**
     * Stop a previously started server
     */
    void stop() @safe
    {
        listener.stopListening();
        queue.close();
        context.close();
    }

private:

    ServiceContext context;
    HTTPServerSettings settings;
    HTTPListener listener;
    URLRouter router;
    VesselEventQueue queue;
}
