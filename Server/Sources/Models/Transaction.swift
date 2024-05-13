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

import Foundation
import OTel

/// Represents a sum of money that was moved in or out of a user's Account for a specific purpose.
public struct Transaction: Codable, Hashable, Identifiable, Sendable {

    // MARK: - Properties

    /// Primary key
    public let id: String

    /// The Account that the transaction applies to
    public let accountID: Account.ID

    /// The date/time that the transaction occurred
    public let instant: Date

    /// The amount of Money involved
    public let amount: Money

    /// A free-form text description of the transaction. Used when we can't display an enriched description
    public let description: String

    /// The category of the transaction. eg Transfer, Payment, Groceries, Eating and Drinking Out
    public let category: String

    /// More specific details depending on the type of transaction, eg card details, payment details, etc
    public let details: Details

    /// The source span that updated this model.
    /// This is used to associate spans where subscribers receive updated models with the trace that changed the model.
    public let updatedBy: OTelSpanContext?

    // MARK: - Initialisation

    /// Memberwise initialiser for a card-based transaction
    public init(id: String, accountID: Account.ID, instant: Date, cardDetails: CardDetails, amount: Money, category: String, description: String, updatedBy: OTelSpanContext?) {
        self.id = id
        self.accountID = accountID
        self.instant = instant
        self.details = .card(cardDetails)
        self.amount = amount
        self.description = description
        self.category = category
        self.updatedBy = updatedBy
    }

    /// Memberwise initialiser for a payment transaction
    public init(id: String, accountID: Account.ID, instant: Date, paymentDetails: PaymentDetails, amount: Money, category: String, description: String, updatedBy: OTelSpanContext?) {
        self.id = id
        self.accountID = accountID
        self.instant = instant
        self.details = .payment(paymentDetails)
        self.amount = amount
        self.description = description
        self.category = category
        self.updatedBy = updatedBy
    }

    /// Memberwise initialiser for a transfer-based transaction
    public init(id: String, accountID: Account.ID, instant: Date, transferDetails: TransferDetails, amount: Money, category: String, description: String, updatedBy: OTelSpanContext?) {
        self.id = id
        self.accountID = accountID
        self.instant = instant
        self.details = .transfer(transferDetails)
        self.amount = amount
        self.description = description
        self.category = category
        self.updatedBy = updatedBy
    }

}


// MARK: - Transaction Details

public extension Transaction {

    /// More specific details depending on the type of transaction, eg card details, payment details, etc
    enum Details: Codable, Hashable, Sendable {
        case card(CardDetails)
        case payment(PaymentDetails)
        case transfer(TransferDetails)
    }

}


// MARK: - Card-based Transaction

public extension Transaction {

    /// A card purchase for a merchant (online or in-person) using your card
    struct CardDetails: Codable, Hashable, Sendable {
        public let merchantID: Merchant.ID

        public init(merchantID: Merchant.ID) {
            self.merchantID = merchantID
        }
    }

}


// MARK: - Transfers

public extension Transaction {

    /// A transfer between your own accounts
    struct TransferDetails: Codable, Hashable, Sendable {
        public let fromAccount: Account.ID
        public let toAccount: Account.ID
        public let receiptNumber: String

        public init(fromAccount: Account.ID, toAccount: Account.ID, receiptNumber: String) {
            self.fromAccount = fromAccount
            self.toAccount = toAccount
            self.receiptNumber = receiptNumber
        }
    }

}


// MARK: - Payments

public extension Transaction {

    /// A payment between two bank accounts, not necessarily the same owner
    struct PaymentDetails: Codable, Hashable, Sendable {
        public let fromAccount: Account.ID
        public let toAccount: Account.ID
        public let receiptNumber: String

        public init(fromAccount: Account.ID, toAccount: Account.ID, receiptNumber: String) {
            self.fromAccount = fromAccount
            self.toAccount = toAccount
            self.receiptNumber = receiptNumber
        }
    }

}
