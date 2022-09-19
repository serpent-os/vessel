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

import vibe.d;
import moss.db.keyvalue.orm;
import moss.db.keyvalue.interfaces;
import moss.db.keyvalue.errors;
import moss.db.keyvalue;

import vessel.rest;
import vessel.collection;

/**
 * Main lifecycle management for the Vessel Daemon
 */
public final class VesselApplication
{
    /**
     * Construct a new VesselApplication
     */
    this() @safe
    {
        /**
         * Set up listener config
         */
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
        listener = listenHTTP(settings, router);

        runWorkerTask({ auto c = new PackageCollection("."); c.serve(); });
    }

    /**
     * Stop a previously started server
     */
    void stop() @safe
    {
        listener.stopListening();
        () @trusted { send(locate("collection"), StopServing()); }();
    }

private:

    HTTPServerSettings settings;
    HTTPListener listener;
    URLRouter router;
}
