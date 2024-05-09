//
//  SwiftUIView.swift
//  BokBank
//
//  Created by Rob Amos on 7/5/2024.
//

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
