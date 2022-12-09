/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.setup
 *
 * Setup UI for vessel
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.setup;

import vibe.d;
import moss.service.context;

/**
 * Main web frontend for Vessel
 */
@path("/") public final class VesselSetup
{
    @disable this();

    /**
     * Construct new VesselWeb
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * / redirects to make our intent obvious
     */
    void index() @safe
    {
        immutable path = request.path.endsWith("/") ? request.path[0 .. $ - 1] : request.path;
        redirect(format!"%s/setup"(path));
    }

    /**
     * Real index page
     */
    @path("setup") @method(HTTPMethod.GET)
    void setupIndex() @safe
    {
        render!"setup/index.dt";
    }

private:

    ServiceContext context;
}
