/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.rest
 *
 * REST API for Vessel
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.rest;

import moss.service.context;
import moss.service.models.endpoints;
import moss.service.interfaces.vessel;
import std.exception : assumeUnique;
import std.stdint : uint64_t;
import vessel.messaging;
import vibe.d;

/**
 * Concrete implementation of the interface
 */
public final class VesselService : VesselAPI
{
    @disable this();

    mixin AppAuthenticatorContext;

    /**
     * Construct VesselAPI implementation with knowledge of the worker
     */
    this(ServiceContext context, VesselEventQueue queue) @safe
    {
        this.context = context;
        this.queue = queue;
    }

    override void importBinaries(uint64_t reportID, Collectable[] collectables, NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden, "Token missing");
        SummitEndpoint endpoint;

        /* Who rang? */
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, token.payload.sub));
        enforceHTTP(err.isNull, HTTPStatus.forbidden, err.message);

        string[] uris;
        string[] hashes;
        foreach (col; collectables)
        {
            if (col.type != CollectableType.Package)
            {
                continue;
            }
            hashes ~= col.sha256sum;
            uris ~= col.uri;
        }
        VesselEvent event = () @trusted {
            return ImportStonesEvent(reportID, endpoint, assumeUnique(uris), assumeUnique(hashes));
        }();
        queue.put(event);
    }

private:

    ServiceContext context;
    VesselEventQueue queue;
}
