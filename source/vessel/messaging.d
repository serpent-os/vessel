/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.messaging
 *
 * Interthread communication
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.messaging;

import vibe.d;
public import vibe.core.channel;
public import taggedalgebraic.taggedalgebraic;
public import std.stdint : uint64_t;
import moss.service.models.endpoints;

/**
 * A set of origins and index-matched hashes
 */
public struct ImportStonesEvent
{
    /**
     * Remote ID for reporting
     */
    uint64_t reportID;

    /*
     * Endpoint sending the import event
     */
    SummitEndpoint endpoint;

    /**
     * Remote URIs for the stones
     */
    immutable(string[]) uris;

    /**
     * SHA256 hashsums
     */
    immutable(string[]) hashes;
}

/**
 * Our algebraic event is composed of "events"
 */
public union VesselEventSet
{
    /**
     * Requested to import a bunch of stones
     */
    ImportStonesEvent importStones;
}

/**
 * An almost-sumtype of events
 */
public alias VesselEvent = TaggedAlgebraic!VesselEventSet;

/**
 * The worker event queue is a pumping of VesselEvent
 * algebraic type
 */
public alias VesselEventQueue = Channel!(VesselEvent, 500);
