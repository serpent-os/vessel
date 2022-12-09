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
import vibe.core.channel;
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
    this(ServiceContext context, Channel!(bool, 1) doneWork) @safe
    {
        this.context = context;
        this.doneWork = doneWork;
        _router = new URLRouter();
        _router.registerWebInterface(this);
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

    /**
     * Returns: router property
     */
    @noRoute pragma(inline, true) pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

private:

    ServiceContext context;
    URLRouter _router;
    Channel!(bool, 1) doneWork;
}
