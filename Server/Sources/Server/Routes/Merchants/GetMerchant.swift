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

    /// Registers the route to retrieve the specified Merchant for the authenticated user
    func registerGetMerchant(storage: StorageService) {
        get("/merchants/:merchant") { _, context in
            guard
                let merchantID = context.parameters.get("merchant"),
                let merchant = try await storage.merchantsRepository.merchant(for: context.userID, merchant: merchantID).first()
            else {
                throw HTTPError(.notFound)
            }

            return merchant
        }
    }

}
