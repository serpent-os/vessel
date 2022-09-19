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

module vessel.models.package_collection;

public import moss.db.keyvalue.orm;

/**
 * A PackageCollection is composed of branches.
 *
 */
public @Model struct PackageCollection
{
    /**
     * Unique identifier for the PackageCollection
     */
    @PrimaryKey string name;
}
