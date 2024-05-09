//
//  BokCurrencyFormatStyle.swift
//  BokBank
//
//  Created by Rob Amos on 6/5/2024.
//

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
            return (value.amount * -1).formatted(.currency(code: value.currency.rawValue))
        } else {
            return value.amount.formatted(.currency(code: value.currency.rawValue).sign(strategy: .always(showZero: false)))
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
