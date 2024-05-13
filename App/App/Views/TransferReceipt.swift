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

struct TransferReceipt: View {

    // MARK: - Properties

    let receipt: Models.Transaction.TransferDetails
    @Binding var isPresented: ContentViewModel.TransferAccounts?


    // MARK: - View

    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "checkmark.seal")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 100)
                .foregroundStyle(Color.green)
            Text("Transfer Complete")
                .font(.headline)

            Text("Receipt number:\n\(receipt.receiptNumber)")
                .font(.caption)
                .multilineTextAlignment(.center)

            Button("Done") {
                isPresented = nil
            }
        }
        .navigationTitle("Transfer Receipt")
        .navigationBarBackButtonHidden()
    }

}

#Preview {
    NavigationStack {
        TransferReceipt(
            receipt: .init(
                fromAccount: Account.makePreviewTransactingAccount().id,
                toAccount: Account.makePreviewSavingsAccount().id,
                receiptNumber: UUID().uuidString
            ),
            isPresented: .constant(nil)
        )
    }
}
