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

public extension AsyncSequence {

    /// Returns the first element the AsyncSequence emits and completes
    func first() async throws -> Element? {
        try await first(where: { _ in true })
    }

}
