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

import moss.core.errors;
import moss.service.context;
import moss.service.interfaces;
import moss.service.models;
import moss.service.pairing;
import std.array : array;
import std.file : exists;
import vessel.messaging;
import vessel.models.settings;
import vessel.web.accounts;
import vibe.d;

/**
 * Main web frontend for Vessel
 */
@path("/") public final class VesselWeb
{
    @disable this();

    /**
     * Construct new VesselWeb
     */
    @noRoute this(ServiceContext context, PairingManager pairingManager,
            VesselEventQueue queue, URLRouter router) @safe
    {
        this.context = context;
        this.queue = queue;
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

    /** 
     * Accept an incoming endpoint request
     *
     * Params:
     *   _id = Endpoint to accept
     */
    @path("/vsl/accept/:id") @method(HTTPMethod.GET) void acceptEndpoint(string _id) @safe
    {
        SummitEndpoint endpoint;
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        scope (exit)
        {
            redirect("/");
        }

        /* Get the service account */
        immutable name = format!"%s%s"(serviceAccountPrefix, _id);
        context.accountManager.registerService(name, endpoint.hostAddress)
            .match!((Account serviceAccount) {
                /* Correctly store bearer token now */
                pairingManager.createBearerToken(endpoint, serviceAccount,
                    "summit").match!((BearerToken bearerToken) {
                    /* Acknowledge our acceptance */
                    pairingManager.acceptFrom(endpoint, bearerToken,
                    EnrolmentRole.RepositoryManager, EnrolmentRole.Hub).match!((Success s) {
                        logInfo(format!"Successfully paired with remote endpoint %s"(
                        endpoint.hostAddress));
                    }, (Failure f) {
                        logError(format!"Failed to pair with remote endpoint %s: %s"(endpoint.hostAddress,
                        f.message));
                    });
                }, (Failure f) {
                    logError(format!"Failed to create bearer token: %s"(f.message));
                });
            }, (DatabaseError err) {
                logError(format!"Failed to lookup service account for %s: %s"(_id, err.message));
            });
    }

    @path("/vsl/import") @method(HTTPMethod.GET)
    void importStones(string importPath) @safe
    {
        enforceHTTP(importPath.exists, HTTPStatus.notFound,
                "The specified import directory does not exist");

        VesselEvent event = ImportDirectoryEvent(importPath);
        queue.put(event);
        redirect("/");
    }

private:

    ServiceContext context;
    PairingManager pairingManager;
    VesselEventQueue queue;
}
