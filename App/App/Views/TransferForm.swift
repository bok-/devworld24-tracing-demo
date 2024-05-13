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
import Tracing

struct TransferForm: View {

    // MARK: - Properties

    @State var sourceAccount: Account
    @State var targetAccount: Account
    @State var amount: Decimal

    @State var transferReceipt: Models.Transaction.TransferDetails?
    @State var disableDismiss = false

    @Binding var isPresented: ContentViewModel.TransferAccounts?

    private var appCore: AppCore
    @Environment(\.defaultMinListRowHeight) private var rowHeight


    // MARK: - Initialisation

    init(sourceAccount: Account, targetAccount: Account, amount: Decimal, isPresented: Binding<ContentViewModel.TransferAccounts?>, appCore: AppCore) {
        self.sourceAccount = sourceAccount
        self.targetAccount = targetAccount
        self.amount = amount
        self._isPresented = isPresented
        self.appCore = appCore
    }


    // MARK: - View Body

    @ViewBuilder
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("From")
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(sourceAccount.name)")
                        Text("\(sourceAccount.number)")
                            .font(.caption)
                    }
                }

                HStack {
                    Text("To")
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(targetAccount.name)")
                        Text("\(targetAccount.number)")
                            .font(.caption)
                    }
                }
            } footer: {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            let source = sourceAccount
                            sourceAccount = targetAccount
                            targetAccount = source
                        }

                    } label: {
                        Label("Swap", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            Section {
                HStack {
                    Text("Amount")
                        .font(.headline)
                    TextField(
                        "Amount",
                        value: $amount,
                        format: .currency(code: "AUD")
                    )
                    .multilineTextAlignment(.trailing)
                }
            }

            Section {} footer: {
                AsyncButton {
                    try await withSpan("Tapped Transfer Now") { _ in
                        do {
                            disableDismiss = true
                            transferReceipt = try await appCore.paymentsClient
                                .transfer(
                                    from: sourceAccount,
                                    to: targetAccount,
                                    amount: Money(amount: amount, currency: .aud)
                                )
                            disableDismiss = false
                        } catch {
                            disableDismiss = false
                            throw error
                        }
                    }

                } label: {
                    Text("Transfer Now")
                        .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(amount <= 0)
            }
        }

        .navigationTitle("Transfer")
        .interactiveDismissDisabled(disableDismiss)
        .navigationDestination(item: $transferReceipt) { receipt in
            TransferReceipt(receipt: receipt, isPresented: $isPresented)
        }

    }


}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.background)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.accentColor, in: Rectangle())
    }
}

// MARK: - Previews

// #Preview {
//    TransferForm(
//        sourceAccount: .makePreviewTransactingAccount(),
//        targetAccount: .makePreviewSavingsAccount(),
//        amount: 10
//    )
// }
