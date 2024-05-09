//
//  ContentViewModel.swift
//  BokBank
//
//  Created by Rob Amos on 6/5/2024.
//

import Core
import Foundation
import SwiftUI
import Tracing

@Observable
final class ContentViewModel {

    // MARK: - Properties

    var account: Result<Account, Error>?
    var transactions: Result<[TransactionGroup], Error>?
    var merchants: Result<[Merchant], Error>?

    var allAccounts: Result<[Account], Error>?

    private var accountsTask: Task<Void, Never>?
    private var transactionsTask: Task<Void, Never>?
    private var merchantsTask: Task<Void, Never>?


    // MARK: - Initialisation

    /// Creates an auto-updating ContentViewModel using the given AppCore
    init(appCore: AppCore) {
        setupBindings(appCore: appCore)
    }

    /// Memberwise initialiser (testing)
    init(
        accountResult: Result<Account, Error>?,
        transactionsResult: Result<[TransactionGroup], Error>?,
        merchantsResult: Result<[Merchant], Error>?,
        allAccountsResult: Result<[Account], Error>?
    ) {
        self.account = accountResult
        self.transactions = transactionsResult
        self.merchants = merchantsResult
        self.allAccounts = allAccountsResult
    }

    /// Testing / Previewable Initialiser
    init(account: Account, transactions: [Models.Transaction], merchants: [Merchant]) {
        self.allAccounts = .success([account])
        self.transactions = .success(transactions.chunkedByDate())
        self.merchants = .success(merchants)
    }

    deinit {
        accountsTask?.cancel()
        merchantsTask?.cancel()
        transactionsTask?.cancel()
    }

    // MARK: - Bindings

    private func setupBindings(appCore: AppCore) {
        self.accountsTask = Task.detached { [weak self] in
            do {
                for try await accounts in try appCore.accountsRepository.allAccounts(for: appCore.userID).removeDuplicates() {
                    if let account = accounts.first(where: { $0.product == .transacting }) {
                        withAnimation {
                            self?.account = .success(account)
                            self?.allAccounts = .success(accounts)
                        }
                        self?.setupTransactionsBindings(appCore: appCore, account: account)

                    } else {
                        withAnimation {
                            self?.account = .failure(ContentViewModelError.missingAccounts)
                            self?.allAccounts = .success([])
                        }
                    }
                }
            } catch {
                withAnimation {
                    self?.account = .failure(error)
                    self?.allAccounts = .failure(error)
                }
            }
        }
        self.merchantsTask = Task.detached { [weak self] in
            do {
                for try await merchants in try appCore.merchantsRepository.allMerchants(for: appCore.userID).removeDuplicates() {
                    withAnimation {
                        self?.merchants = .success(merchants)
                    }
                }
            } catch {
                withAnimation {
                    self?.merchants = .failure(error)
                }
            }
        }
    }

    private func setupTransactionsBindings(appCore: AppCore, account: Account) {
        self.transactionsTask?.cancel()
        self.transactionsTask = Task.detached { [weak self] in
            do {
                for try await transactions in try appCore.transactionsRepository.transactions(for: appCore.userID, account: account.id).removeDuplicates() {
                    withAnimation {
                        self?.transactions = .success(transactions.chunkedByDate())
                    }
                }
            } catch {
                withAnimation {
                    self?.transactions = .failure(error)
                }
            }
        }
    }


    // MARK: - Helpers

    var transactionGroups: [TransactionGroup]? {
        if case .success(let groups) = transactions {
            return groups
        } else {
            return nil
        }
    }

    struct TransferAccounts: Identifiable, Hashable {
        let source: Account
        let target: Account
        var id: String {
            source.id + target.id
        }
    }

    var transferAccounts: TransferAccounts? {
        guard
            case .success(let accounts) = allAccounts,
            let source = accounts.first(where: { $0.product == .transacting }),
            let target = accounts.first(where: { $0.product == .savings })
        else {
            return nil
        }
        return TransferAccounts(source: source, target: target)
    }

}


// MARK: - Error Handling

private enum ContentViewModelError: LocalizedError {
    case missingAccounts

    var errorDescription: String? {
        switch self {
        case .missingAccounts:                  "No accounts were found."
        }
    }
}
