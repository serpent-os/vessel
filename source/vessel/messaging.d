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

/**
 * Simple request to shut down the main loop
 */
public struct StopServing
{
}

/**
 * Send acknowledgement to the main thread that the worker is
 * now ready to go, prior to serving API requests.
 */
public struct WorkerStarted
{
    Tid workerTid;
}

/**
 * Frontend got told to import a batch of stones, lets go import them
 */
public struct ImportStones
{
    /**
     * Each URI corresponds to a hash of the same index
     */
    immutable(string[]) uris;

    /**
     * The set of hashes
     */
    immutable(string[]) hashes;
}
