/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * vessel.models.release
 *
 * Release management
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module vessel.models.release;

public import moss.db.keyvalue.orm;

/**
 * A PackageCollection is composed of branches.
 */
public @Model struct Release
{
    /**
     * Unique identifier for the Release
     */
    @PrimaryKey string name;

    /**
     * Package IDs within this Release
     */
    string[] pkgIDs;
}
