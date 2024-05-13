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
import SwiftUI

struct ContentView: View {

    // MARK: - State

    @Bindable var viewModel: ContentViewModel

    @State var transferAccounts: ContentViewModel.TransferAccounts?

    @EnvironmentObject private var appCore: AppCore

    // MARK: - Body

    var body: some View {
        List {
            Section {
                LoadingView(viewModel.account) { result in
                    ResultView(result) { account in
                        VStack(spacing: 8) {
                            Text(account.name)
                                .font(.headline)
                            Text(account.balance.amount.formatted(.currency(code: account.balance.currency.rawValue)))
                                .font(.largeTitle)
                            Text("\(account.bsb), \(account.number)")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                    }
                }
                .padding([ .top, .bottom ], 100)
                .frame(maxWidth: .infinity, maxHeight: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/)
            }
            if let transactions = viewModel.transactions {
                ResultView(transactions) { transactionGroups in
                    if transactionGroups.isEmpty {
                        Section {
                            Text("No transactions found.\nGo spend some money!")
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(transactionGroups, id: \.date) { group in
                            Section(group.date.formatted(date: .complete, time: .omitted)) {
                                ForEach(group.transactions) { transaction in
                                    TransactionCell(
                                        transaction: transaction,
                                        merchant: {
                                            if
                                                case let .card(card) = transaction.details,
                                                case let .success(merchants) = viewModel.merchants
                                            {
                                                merchants.first(where: { $0.id == card.merchantID })

                                            } else {
                                                nil
                                            }
                                        }()
                                    )
                                }
                            }
                        }
                    }
                }
            }

        }
        .listStyle(.plain)
        .sheet(item: $transferAccounts) { accounts in
            NavigationStack {
                TransferForm(
                    sourceAccount: accounts.source,
                    targetAccount: accounts.target,
                    amount: 0,
                    isPresented: $transferAccounts,
                    appCore: appCore
                )
            }
        }
        .navigationTitle("BokBank™")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    transferAccounts = viewModel.transferAccounts

                } label: {
                    Text("Transfer")
                }
                .disabled(viewModel.transferAccounts == nil)
            }
        }
    }
}

#Preview("Loading") {
    ContentView(
        viewModel: .init(
            accountResult: nil,
            transactionsResult: nil,
            merchantsResult: nil,
            allAccountsResult: nil
        )
    )
}

#Preview("Empty transactions list") {
    ContentView(
        viewModel: .init(
            account: .makePreviewTransactingAccount(),
            transactions: [],
            merchants: []
        )
    )
}

#Preview("One transaction") {
    ContentView(
        viewModel: .init(
            account: .makePreviewTransactingAccount(),
            transactions: [
                .makePreviewCardTransaction(),
                .makePreviewOutgoingPayment(),
                .makePreviewIncomingPayment(),
                .makePreviewOutgoingTransfer(),
                .makePreviewIncomingTransfer(),
            ],
            merchants: [
                .makePreviewWoolworths(),
            ]
        )
    )
}


// MARK: - Test Fixtures

extension Account {

    static func makePreviewTransactingAccount() -> Account {
        .init(
            id: "888-888/999999999",
            bsb: "888-888",
            number: "999999999",
            name: "Transacting Account",
            product: .transacting,
            balance: Money(amount: 100, currency: .aud),
            updatedBy: nil
        )
    }

    static func makePreviewSavingsAccount() -> Account {
        .init(
            id: "888-888/999999999",
            bsb: "888-888",
            number: "999999998",
            name: "Savings Account",
            product: .transacting,
            balance: Money(amount: 0, currency: .aud),
            updatedBy: nil
        )
    }

}
