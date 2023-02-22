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
 * Used to report success of an import
 */
public struct ReportSuccessEvent
{
    /** 
     * Remote ID for reporting
     */
    uint64_t reportID;

    /** 
     * Who initiated the job
     */
    SummitEndpoint endpoint;
}

/** 
 * Used to report failure of an import
 */
public struct ReportFailureEvent
{
    /** 
     * Remote ID for reporting
     */
    uint64_t reportID;

    /** 
     * Who initiated the job
     */
    SummitEndpoint endpoint;
}

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
 * Reporting queue - handled in main vibe.d thread
 */
public union ReportEventSet
{
    /** 
     * Send a failure report
     */
    ReportFailureEvent reportFailure;

    /** 
     * Send a success report
     */
    ReportSuccessEvent reportSuccess;
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

/** 
 * All possible report events
 */
public alias ReportEvent = TaggedAlgebraic!ReportEventSet;

/** 
 * The service worker sends events back to the main vibe.d
 * thread for async reporting to the main summit instance
 */
public alias ReportEventQueue = Channel!(ReportEvent, 500);
