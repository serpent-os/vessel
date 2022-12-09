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
import vessel.web;
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
        /* Primary routing mechanism for our API */
        _router = new URLRouter();
        queue = createChannel!(VesselEvent, 500);

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

        _router.registerRestInterface(new VesselAPI(queue));
        _router.registerWebInterface(new VesselWeb(context));
        _router.rebuild();
    }

    /**
     * Returns: Router property
     */
    @noRoute pragma(inline, true) pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    @noRoute void close() @safe
    {
        logWarn("VesselApp.close(): Not yet implemented");
    }

private:

    ServiceContext context;
    URLRouter _router;
    VesselEventQueue queue;
}
