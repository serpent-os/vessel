/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry point into vessel
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module main;

import libsodium;
import moss.service.context;
import std.path : absolutePath, asNormalizedPath;
import vessel.app;
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
    logInfo("Initialising libsodium");
    immutable sret = () @trusted { return sodium_init(); }();
    enforce(sret == 0, "Failed to initialise libsodium");

    immutable rootDir = ".".absolutePath.asNormalizedPath.to!string;
    setLogLevel(LogLevel.trace);

    auto context = new ServiceContext(rootDir);
    auto app = new VesselApplication(context);
    scope (exit)
    {
        app.stop();
    }
    app.start();
    return runApplication();
}
