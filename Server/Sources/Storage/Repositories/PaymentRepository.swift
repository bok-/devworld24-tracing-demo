
import Foundation
import GRDB
import Models
import OTel
import Tracing

final class StoragePaymentsRepository: Sendable {

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

}


// MARK: - Payments Repository

/// Access to the local payments database
public protocol PaymentsRepository {

    /// Makes a transfer between the specified user's accounts
    func transfer(
        userID: User.ID,
        from source: Account.ID,
        to target: Account.ID,
        amount: Money
    ) async throws -> Transaction.TransferDetails

}

public enum PaymentError: Error {
    case invalidSourceAccount(Account.ID)
    case invalidTargetAccount(Account.ID)
    case insufficientFunds

    public var errorDescription: String {
        switch self {
        case .invalidSourceAccount:             "Invalid source account"
        case .invalidTargetAccount:             "Invalid destination account"
        case .insufficientFunds:                "Insufficient funds"
        }
    }
}

extension StoragePaymentsRepository: PaymentsRepository {

    func transfer(
        userID: User.ID,
        from source: Account.ID,
        to target: Account.ID,
        amount: Money
    ) async throws -> Transaction.TransferDetails {
        // We do everything inside a single database transaction
        // to prevent race conditions
        try await storage.write(to: userID) { db in

            // Verify accounts and balances
            guard let sourceAccount = try AccountRecord.fetchOne(db, key: source) else {
                throw PaymentError.invalidSourceAccount(source)
            }
            guard let targetAccount = try AccountRecord.fetchOne(db, key: target) else {
                throw PaymentError.invalidTargetAccount(target)
            }
            guard sourceAccount.balance >= amount else {
                throw PaymentError.insufficientFunds
            }

            // Make the transfer
            sourceAccount.balance -= amount
            sourceAccount.updatedBy = ServiceContext.current?.spanContext
            targetAccount.balance += amount
            targetAccount.updatedBy = ServiceContext.current?.spanContext

            // Create transactions on both accounts
            let receiptNumber = UUID().uuidString.lowercased()
            let payment = TransactionRecord.Details.transfer(fromAccount: sourceAccount.id, toAccount: targetAccount.id, receiptNumber: receiptNumber)
            let description = "Transfer from \(sourceAccount.number) to \(targetAccount.number)"

            let sourceTransaction = TransactionRecord(
                id: UUID().uuidString.lowercased(),
                accountID: sourceAccount.id,
                instant: .now,
                amount: amount.negating(),
                description: description,
                category: "Transfers",
                details: payment,
                updatedBy: ServiceContext.current?.spanContext
            )
            let targetTransaction = TransactionRecord(
                id: UUID().uuidString.lowercased(),
                accountID: targetAccount.id,
                instant: .now,
                amount: amount,
                description: description,
                category: "Transfers",
                details: payment,
                updatedBy: ServiceContext.current?.spanContext
            )

            // Save all of those
            try sourceAccount.save(db)
            try targetAccount.save(db)
            try sourceTransaction.insert(db)
            try targetTransaction.insert(db)

            // Return the payment
            return Transaction.TransferDetails(fromAccount: sourceAccount.id, toAccount: targetAccount.id, receiptNumber: receiptNumber)
        }
    }

}

// MARK: - Storage Access

public extension StorageService {
    var paymentsRepository: PaymentsRepository {
        StoragePaymentsRepository(storage: self)
    }
}
