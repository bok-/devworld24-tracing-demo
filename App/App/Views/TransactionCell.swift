//
//  TransactionCell.swift
//  BokBank
//
//  Created by Rob Amos on 6/5/2024.
//

import Core
import Foundation
import SwiftUI

struct TransactionCell: View {

    let transaction: Models.Transaction
    let merchant: Merchant?

    var isTransfer: Bool {
        if case .transfer = transaction.details {
            return true
        } else {
            return false
        }
    }

    var body: some View {
        HStack {
            if let imageURL = (merchant?.logoURL).flatMap(URL.init(string:)) {
                AsyncFailableImage(imageURL: imageURL)
                    .frame(width: 40)
                    .padding(2)
            } else {
                Image(systemName: "dollarsign")
                    .resizable()
                    .symbolVariant(isTransfer ? .circle.fill : .circle)
                    .aspectRatio(contentMode: .fit)
                    .padding(2)
                    .frame(width: 40)
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading) {
                HStack {
                    if let merchant {
                        Text(merchant.name)
                            .lineLimit(1)
                    } else {
                        switch transaction.details {
                        case .card:
                            Text(transaction.description)
                                .lineLimit(1)

                        case .payment(let paymentDetails):
                            if paymentDetails.toAccount == transaction.accountID {
                                Text("Payment received from \(paymentDetails.fromAccount)")
                                    .lineLimit(1)
                            } else {
                                Text("Payment to \(paymentDetails.toAccount)")
                                    .lineLimit(1)
                            }

                        case .transfer(let transferDetails):
                            if transferDetails.toAccount == transaction.accountID {
                                Text("Transfer from \(transferDetails.fromAccount)")
                                    .lineLimit(1)
                            } else {
                                Text("Transfer to \(transferDetails.toAccount)")
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer()
                    Text(transaction.amount.formatted(.bokCurrency))
                        .font(.headline)
                        .foregroundStyle(transaction.amount.amount > 0 ? Color.green : Color.primary)
                }
                Text(transaction.category)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    List {
        TransactionCell(
            transaction: .makePreviewCardTransaction(),
            merchant: .makePreviewWoolworths()
        )

        TransactionCell(
            transaction: .makePreviewOutgoingPayment(),
            merchant: nil
        )

        TransactionCell(
            transaction: .makePreviewIncomingPayment(),
            merchant: nil
        )

        TransactionCell(
            transaction: .makePreviewOutgoingTransfer(),
            merchant: nil
        )

        TransactionCell(
            transaction: .makePreviewIncomingTransfer(),
            merchant: nil
        )
    }
    .listStyle(.plain)
}

// MARK: - Preview Fixtures

extension Models.Transaction {

    static func makePreviewCardTransaction() -> Self {
        .init(
            id: UUID().uuidString,
            accountID: "888888/123456789",
            instant: .now,
            cardDetails: .init(merchantID: "woolworths"),
            amount: Money(amount: 12.50, currency: .aud),
            category: "Groceries",
            description: "VISA DEBIT PURCHASE CARD 9999 WOOLWORTHS PLUMMER ST FISHERMANS BEND",
            updatedBy: nil
        )
    }

    static func makePreviewOutgoingPayment() -> Self {
        .init(
            id: UUID().uuidString,
            accountID: "888888/123456789",
            instant: .now,
            paymentDetails: .init(fromAccount: "888888/123456789", toAccount: "014111/123456789", receiptNumber: "123456"),
            amount: Money(amount: 99, currency: .aud),
            category: "Other Payments",
            description: "PAYMENT TO 014111/123456789",
            updatedBy: nil
        )
    }

    static func makePreviewIncomingPayment() -> Self {
        .init(
            id: UUID().uuidString,
            accountID: "888888/123456789",
            instant: .now,
            paymentDetails: .init(fromAccount: "014111/123456789", toAccount: "888888/123456789", receiptNumber: "123456"),
            amount: Money(amount: 159.65, currency: .aud),
            category: "Other Payments",
            description: "PAYMENT TO 014111/123456789",
            updatedBy: nil
        )
    }

    static func makePreviewOutgoingTransfer() -> Self {
        .init(
            id: UUID().uuidString,
            accountID: "888888/123456789",
            instant: .now,
            transferDetails: .init(fromAccount: "888888/123456789", toAccount: "014111/123456789", receiptNumber: "123456"),
            amount: Money(amount: 10008.10, currency: .aud),
            category: "Transfers",
            description: "PAYMENT TO 014111/123456789",
            updatedBy: nil
        )
    }

    static func makePreviewIncomingTransfer() -> Self {
        .init(
            id: UUID().uuidString,
            accountID: "888888/123456789",
            instant: .now,
            transferDetails: .init(fromAccount: "014111/123456789", toAccount: "888888/123456789", receiptNumber: "123456"),
            amount: Money(amount: 0.50, currency: .aud),
            category: "Transfers",
            description: "PAYMENT TO 014111/123456789",
            updatedBy: nil
        )
    }

}

extension Merchant {

    static func makePreviewWoolworths() -> Self {
        .init(
            id: "woolworths",
            name: "Woolworths (Fishermans Bend)",
            address: "477/481 Plummer St, Port Melbourne VIC 3207",
            location: .coordinate(latitude: -37.83131340325488, longitude: 144.93064975346516),
            logoURL: "https://cdn0.woolworths.media/content/content/icon-header-logo-only.png",
            updatedBy: nil
        )
    }

}
