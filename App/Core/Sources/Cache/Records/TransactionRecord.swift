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
import GRDB
import Models

public final class TransactionRecord: Codable, PersistableRecord, FetchableRecord {

    // MARK: - Properties

    let id: String
    let accountID: String
    let instant: Date
    let amount: Money
    let description: String
    let category: String
    let details: Details

    enum Details: Codable {
        case card(merchantID: String)
        case payment(fromAccount: String, toAccount: String, receiptNumber: String)
        case transfer(fromAccount: String, toAccount: String, receiptNumber: String)
    }


    // MARK: - Initialisation

    /// Memberwise initialiser
    init(
        id: String,
        accountID: String,
        instant: Date,
        amount: Money,
        description: String,
        category: String,
        details: Details
    ) {
        self.id = id
        self.accountID = accountID
        self.instant = instant
        self.amount = amount
        self.description = description
        self.category = category
        self.details = details
    }

}


// MARK: - TableRecord Conformance

extension TransactionRecord {

    public static var databaseTableName: String {
        "transaction"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let accountID = Column(CodingKeys.accountID)
        static let instant = Column(CodingKeys.instant)
        static let amount = Column(CodingKeys.amount)
        static let description = Column(CodingKeys.description)
        static let details = Column(CodingKeys.details)
    }

}


// MARK: - Bridging

extension Transaction {
    init(_ record: TransactionRecord) {
        switch record.details {
        case let .card(merchantID):
            self.init(
                id: record.id,
                accountID: record.accountID,
                instant: record.instant,
                cardDetails: .init(merchantID: merchantID),
                amount: record.amount,
                category: record.category,
                description: record.description,
                updatedBy: nil
            )

        case let .payment(fromAccount, toAccount, receiptNumber):
            self.init(
                id: record.id,
                accountID: record.accountID,
                instant: record.instant,
                paymentDetails: .init(fromAccount: fromAccount, toAccount: toAccount, receiptNumber: receiptNumber),
                amount: record.amount,
                category: record.category,
                description: record.description,
                updatedBy: nil
            )

        case let .transfer(fromAccount, toAccount, receiptNumber):
            self.init(
                id: record.id,
                accountID: record.accountID,
                instant: record.instant,
                transferDetails: .init(fromAccount: fromAccount, toAccount: toAccount, receiptNumber: receiptNumber),
                amount: record.amount,
                category: record.category,
                description: record.description,
                updatedBy: nil
            )
        }
    }
}

public extension TransactionRecord {
    convenience init(_ transaction: Transaction) {
        switch transaction.details {
        case let .card(card):
            self.init(
                id: transaction.id,
                accountID: transaction.accountID,
                instant: transaction.instant,
                amount: transaction.amount,
                description: transaction.description,
                category: transaction.category,
                details: .card(merchantID: card.merchantID)
            )

        case let .payment(payment):
            self.init(
                id: transaction.id,
                accountID: transaction.accountID,
                instant: transaction.instant,
                amount: transaction.amount,
                description: transaction.description,
                category: transaction.category,
                details: .payment(fromAccount: payment.fromAccount, toAccount: payment.toAccount, receiptNumber: payment.receiptNumber)
            )

        case let .transfer(transfer):
            self.init(
                id: transaction.id,
                accountID: transaction.accountID,
                instant: transaction.instant,
                amount: transaction.amount,
                description: transaction.description,
                category: transaction.category,
                details: .transfer(fromAccount: transfer.fromAccount, toAccount: transfer.toAccount, receiptNumber: transfer.receiptNumber)
            )
        }
    }
}
