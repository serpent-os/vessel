/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.web.accounts
 *
 * Account management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.web.accounts;

import moss.service.context;
import vibe.d;

/**
 * Basic subclass to support local rendering
 */
@path("/accounts") public final class VesselAccountsWeb : AccountsWeb
{
    @disable this();

    /**
     * Construct new accounts web
     */
    this(ServiceContext context) @safe
    {
        super(context.accountManager, context.tokenManager, "vessel");
    }

    override void renderLogin() @safe
    {
        render!"accounts/login.dt";
    }

    override void renderRegister() @safe
    {
        render!"accounts/register.dt";
    }
}
