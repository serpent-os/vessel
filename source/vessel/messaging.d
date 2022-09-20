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

public struct WorkerStarted
{
    Tid workerTid;
}
