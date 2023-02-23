/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.app
 *
 * Main vessel application
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.app;

import moss.service.context;
import moss.service.interfaces;
import moss.service.models.endpoints;
import moss.service.tokens.refresh;
import moss.service.pairing;
import moss.service.server;
import std.algorithm : filter, map;
import std.conv : to;
import std.file : exists, mkdirRecurse;
import std.path : buildPath;
import std.string : format;
import vessel.messaging;
import vessel.models.settings;
import vessel.rest;
import vessel.rest.pairing;
import vessel.serviceworker;
import vessel.web;
import vibe.d;

/**
 * Main lifecycle management for the Vessel Daemon
 */
public final class VesselApplication : Application
{

    @noRoute override void initialize(ServiceContext context) @safe
    {
        /**
         * Set up listener config
         */
        this.context = context;

        const settings = context.appDB.getSettings.tryMatch!((Settings s) => s);
        this.pairingManager = new PairingManager(context, "vessel", settings.instanceURI);

        /* Primary routing mechanism for our API */
        _router = new URLRouter();
        queue = createChannel!(VesselEvent, 500);

        immutable requiredDirs = [
            "public/pool", "public/releases", "public/branches", "staging",
        ];
        auto builderDirs = requiredDirs.map!((i) => context.statePath.buildPath(i))
            .filter!((i) => !i.exists);
        foreach (req; builderDirs)
        {
            logInfo(format!"Constructing tree: %s"(req));
            req.mkdirRecurse();
        }

        reportQueue = createChannel!(ReportEvent, 500);
        runTask(&reportWorker);

        /* Now startup the service *worker* */
        runWorkerTask((VesselEventQueue queue, ReportEventQueue reportQueue, string rootDir) {
            auto c = new ServiceWorker(queue, reportQueue, rootDir);
            c.serve();
        }, queue, reportQueue, context.statePath);

        _router.registerRestInterface(new VesselService(context, queue));
        _router.registerRestInterface(new VesselPairingService(context));
        _router.registerWebInterface(new VesselWeb(context, pairingManager, _router));
    }

    /**
     * Returns: Router property
     */
    @noRoute override pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    @noRoute override void close() @safe
    {
        queue.close();
        reportQueue.close();
    }

private:

    /** 
     * To avoid threading issues, only our main thread has access to
     * the ServiceContext + associated DBs. Therefore the ServiceWorker
     * sends us a message to report on the completion of an import event,
     * and we forward that to the SummitEndpoint specified.
     */
    void reportWorker() @safe
    {
        ReportEvent event;
        while (reportQueue.tryConsumeOne(event))
        {
            final switch (event.kind)
            {
            case ReportEvent.Kind.reportSuccess:
                auto evt = cast(ReportSuccessEvent) event;
                reportStatus(evt.endpoint, evt.reportID, true);
                break;
            case ReportEvent.Kind.reportFailure:
                auto evt = cast(ReportFailureEvent) event;
                reportStatus(evt.endpoint, evt.reportID, false);
                break;
            }
        }
    }

    /** 
     * Internal helper for remote API
     *
     * Params:
     *   endpoint = Remote endpoint
     *   reportID = Task ID in build system
     *   success = Did we get it in?
     */
    void reportStatus(SummitEndpoint endpoint, uint64_t reportID, bool success) @safe
    {
        if (!ensureEndpointUsable(endpoint, context))
        {
            logError(format!"Unable to publish status for %s"(reportID));
            return;
        }

        /* Construct token based proxy */
        auto api = new RestInterfaceClient!SummitAPI(endpoint.hostAddress);
        api.requestFilter = (req) {
            req.headers["Authorization"] = format!"Bearer %s"(endpoint.apiToken);
        };

        /* API call.. */
        try
        {
            if (success)
            {
                api.importSucceeded(reportID, NullableToken());
            }
            else
            {
                api.importFailed(reportID, NullableToken());
            }
        }
        catch (Exception ex)
        {
            logError(format!"Failed to report status to %s: %s"(endpoint.hostAddress, ex.message));
        }
    }

    ServiceContext context;
    URLRouter _router;
    ReportEventQueue reportQueue;
    VesselEventQueue queue;
    PairingManager pairingManager;
}
