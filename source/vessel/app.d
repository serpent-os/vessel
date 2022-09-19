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

import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.orm;
import vibe.d;
import vessel.rest;
import vessel.serviceworker;
import std.path : asNormalizedPath, buildPath, absolutePath;
import std.file : exists, mkdirRecurse;
import std.conv : to;
import std.string : format;

/**
 * Main lifecycle management for the Vessel Daemon
 */
public final class VesselApplication
{
    @disable this();

    /**
     * Construct a new VesselApplication
     */
    this(string rootDir) @safe
    {
        /**
         * Set up listener config
         */
        this.rootDir = rootDir.absolutePath.asNormalizedPath.to!string;
        settings = new HTTPServerSettings();
        settings.bindAddresses = ["localhost",];
        settings.port = 5050;
        settings.disableDistHost = true;
        settings.serverString = "Vessel / 0.0.0";
        settings.useCompressionIfPossible = true;

        /* Primary routing mechanism for our API */
        router = new URLRouter();
        router.registerRestInterface(new VesselAPI());
    }

    /**
     * Start the server
     */
    void start() @safe
    {
        immutable requiredDirs = [
            "public/pool", "public/releases", "public/branches", "database",
        ];
        foreach (req; requiredDirs)
        {
            if (req.exists)
            {
                continue;
            }
            immutable fullPath = rootDir.buildPath(req);
            logInfo(format!"Constructing tree: %s"(fullPath));
            fullPath.mkdirRecurse();
        }
        listener = listenHTTP(settings, router);

        runWorkerTask({ auto c = new ServiceWorker("."); c.serve(); });
    }

    /**
     * Stop a previously started server
     */
    void stop() @safe
    {
        listener.stopListening();
        () @trusted { send(locate("serviceWorker"), StopServing()); }();
    }

private:

    HTTPServerSettings settings;
    HTTPListener listener;
    URLRouter router;
    string rootDir = ".";
}
