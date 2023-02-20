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
import vessel.models.settings;
import moss.service.pairing;

/**
 * Main web frontend for Vessel
 */
@path("/") public final class VesselWeb
{
    @disable this();

    /**
     * Construct new VesselWeb
     */
    @noRoute this(ServiceContext context, PairingManager pairingManager, URLRouter router) @safe
    {
        this.context = context;
        this.pairingManager = pairingManager;
        router.registerWebInterface(cast(AccountsWeb) new VesselAccountsWeb(context));
    }

    /**
     * Render the index page
     */
    void index()
    {
        const publicKey = context.tokenManager.publicKey;
        const settings = context.appDB.getSettings().tryMatch!((Settings s) => s);
        SummitEndpoint[] endpoints;
        context.appDB.view((in tx) @safe {
            auto ls = tx.list!SummitEndpoint;
            endpoints = () @trusted { return ls.array(); }();
            return NoDatabaseError;
        });
        render!("index.dt", endpoints, settings, publicKey);
    }

private:

    ServiceContext context;
    PairingManager pairingManager;
}
