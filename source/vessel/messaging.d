/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.messaging
 *
 * Interthread communication
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.messaging;

import vibe.d;
public import vibe.core.channel;
public import taggedalgebraic.taggedalgebraic;

/**
 * A set of origins and index-matched hashes
 */
public struct ImportStonesEvent
{
    immutable(string[]) uris;
    immutable(string[]) hashes;
}

public union VesselEventSet
{
    ImportStonesEvent importStones;
}

public alias VesselEvent = TaggedAlgebraic!VesselEventSet;

/**
 * The worker event queue is a pumping of VesselEvent
 * algebraic type
 */
public alias VesselEventQueue = Channel!(VesselEvent, 500);
