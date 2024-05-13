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

import Core
import Foundation

/// A currency formatter that shows explicit positives and no signs if the value is negative. Used to represent changes
/// on a transaction ledger.
struct BokCurrencyFormatStyle: FormatStyle {

    typealias FormatInput = Money
    typealias FormatOutput = String

    func format(_ value: Money) -> String {
        // We don't show negatives, only explicit positives
        if value.amount < 0 {
            (value.amount * -1).formatted(.currency(code: value.currency.rawValue))
        } else {
            value.amount.formatted(.currency(code: value.currency.rawValue).sign(strategy: .always(showZero: false)))
        }
    }

}

extension FormatStyle where Self == BokCurrencyFormatStyle {

    static var bokCurrency: BokCurrencyFormatStyle {
        BokCurrencyFormatStyle()
    }

}

extension Money {

    func formatted<S>(_ style: S) -> S.FormatOutput where S: FormatStyle, S.FormatInput == Money {
        style.format(self)
    }

}
