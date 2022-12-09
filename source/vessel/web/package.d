/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.web
 *
 * Web frontend for Vessel
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.web;

import vibe.d;
import moss.service.context;

/**
 * Main web frontend for Vessel
 */
@path("/") public final class VesselWeb
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
     * Render the index page
     */
    void index()
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented);
    }

private:

    ServiceContext context;
}
