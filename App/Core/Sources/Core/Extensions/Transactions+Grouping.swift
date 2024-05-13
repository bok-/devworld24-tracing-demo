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

import Algorithms
import Foundation
import Models

public struct TransactionGroup: Hashable {
    public let date: Date
    public let transactions: ArraySlice<Transaction>
}

public extension [Transaction] {

    /// Chunks up an array of transactions and groups them by day, sorted reverse chronologically
    func chunkedByDate() -> [TransactionGroup] {
        sorted {
            $0.instant > $1.instant
        }
        .chunked(on: {
            Calendar.current.startOfDay(for: $0.instant)
        })
        .map { TransactionGroup(date: $0, transactions: $1) }
    }

}
