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
import moss.service.models;
import moss.service.server;
import std.getopt;
import std.path : absolutePath, asNormalizedPath;
import vessel.app;
import vessel.models;
import vessel.setup;
import vibe.d;

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
    /* It's safer to set this to localhost and allow the user to override (not append!) */
    static string[] defaultAddress = ["localhost"];
    string[] cmdLineAddresses;

    auto opts = () @trusted {
        return getopt(args, config.bundling, "p|port", "Specific port to serve on",
                &portNumber, "a|address", "Host address to bind to", &cmdLineAddresses);
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

    auto server = new Server!(VesselSetup, VesselApplication)(rootDir);
    scope (exit)
    {
        server.close();
    }
    server.serverSettings.bindAddresses = cmdLineAddresses.empty ? defaultAddress : cmdLineAddresses;
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
