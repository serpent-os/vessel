/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry point into vessel
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module main;

import libsodium;
import moss.service.server;
import std.path : absolutePath, asNormalizedPath;
import vessel.app;
import vessel.models;
import moss.service.models;
import vessel.setup;
import vibe.d;
import std.getopt;

/**
 * Main entry point for vessel
 *
 * Params:
 *      args = CLI arguments
 * Returns: 0 if everything went to plan
 */
int main(string[] args)
{
    ushort portNumber = 5050;
    string[] addresses = ["::", "0.0.0.0"];

    auto opts = () @trusted {
        return getopt(args, config.bundling, "p|port", "Specific port to serve on",
                &portNumber, "a|address", "Host address to bind to", &addresses);
    }();

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("vessel:", opts.options);
        return 1;
    }

    logInfo("Initialising libsodium");
    immutable sret = () @trusted { return sodium_init(); }();
    enforce(sret == 0, "Failed to initialise libsodium");

    immutable rootDir = ".".absolutePath.asNormalizedPath.to!string;
    setLogLevel(LogLevel.trace);

    auto server = new Server!(VesselSetup, VesselApplication)(rootDir);
    scope (exit)
    {
        server.close();
    }
    server.serverSettings.bindAddresses = addresses;
    server.serverSettings.port = portNumber;
    server.serverSettings.serverString = "vessel/0.1";
    server.serverSettings.sessionIdCookie = "vessel.session_id";

    /* Configure the model */
    immutable dbErr = server.context.appDB.update((scope tx) => tx.createModel!(Settings,
            SummitEndpoint));
    enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

    const settings = server.context.appDB.getSettings.tryMatch!((Settings s) => s);
    server.mode = settings.setupComplete ? ApplicationMode.Main : ApplicationMode.Setup;
    server.start();

    return runApplication();
}
