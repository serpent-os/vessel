/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.web
 *
 * Web frontend for Vessel
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.web;

import vibe.d;
import std.array : array;
import moss.service.context;
import vessel.web.accounts;
import moss.service.models.endpoints;

/**
 * Main web frontend for Vessel
 */
@path("/") public final class VesselWeb
{
    @disable this();

    /**
     * Construct new VesselWeb
     */
    this(ServiceContext context, URLRouter router) @safe
    {
        this.context = context;
        router.registerWebInterface(cast(AccountsWeb) new VesselAccountsWeb(context));
    }

    /**
     * Render the index page
     */
    void index()
    {
        SummitEndpoint[] endpoints;
        context.appDB.view((in tx) @safe {
            auto ls = tx.list!SummitEndpoint;
            endpoints = () @trusted { return ls.array(); }();
            return NoDatabaseError;
        });
        render!("index.dt", endpoints);
    }

private:

    ServiceContext context;
}
