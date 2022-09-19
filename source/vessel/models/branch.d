/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.models.package_collection
 *
 * Abstraction for a collection
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module vessel.models.branch;

public import moss.db.keyvalue.orm;

/**
 * Multiple branches can exist for a Collection, and each
 * is synced to a specific Release
 */
public @Model struct Branch
{
    /**
     * Unique identifier for the Branch
     */
    @PrimaryKey string name;
}
