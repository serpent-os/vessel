/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.models.record
 *
 * Abstraction for a collection
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.models.record;

public import moss.db.keyvalue.orm;
public import std.stdint : uint64_t;

/**
 * Volatile records map a package *name* to a specific
 * package ID within the MetaDB. It allows for displacement
 * methodology.
 */
public @Model struct VolatileRecord
{
    /**
     * Unique identifier for the Branch
     */
    @PrimaryKey string name;

    /**
     * Package identifier in MetaDB
     */
    string pkgID;

    /**
     * Build release number.
     */
    uint64_t buildRelease = 0;

    /**
     * Source release number
     */
    uint64_t sourceRelease = 0;
}
