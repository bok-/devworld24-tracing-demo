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

import Hummingbird
import Models
import Storage

extension Router<BokRequestContext> {

    /// Registers the route to retrieve a list of Account for the authenticated user
    func registerListAccounts(storage: StorageService) {
        get("/accounts") { _, context in
            try await storage.accountsRepository
                .allAccounts(for: context.userID)
                .first()
                ?? []
        }
    }

}
