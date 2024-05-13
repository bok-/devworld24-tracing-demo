//===----------------------------------------------------------------------===//
//
// This source file is part of a technology demo for /dev/world 2024.
//
// Copyright © 2024 ANZ. All rights reserved.
// Licensed under the MIT license
//
// See LICENSE for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import GRDB

enum Migrations {

    typealias Migration = (String, (Database) throws -> Void)

    static var allMigrations: [Migration] = [
        creation,
    ]

}


// MARK: - Helpers

func makeMigration(id: String, migrator: @escaping (Database) throws -> Void) -> Migrations.Migration {
    (id, migrator)
}
