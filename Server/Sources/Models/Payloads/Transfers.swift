
/// A request from a User to make a transfer between two of their accounts.
///
/// Both accounts must be owned by the User.
///
public struct TransferRequest: Codable {

    // MARK: - Properties

    /// The source account to transfer the money from
    public let fromAccount: Account.ID

    /// The target account to transfer the money to
    public let toAccount: Account.ID

    /// The amount of money to transfer between the accounts
    public let amount: Money


    // MARK: - Initialisation

    /// Memberwise initialiser
    public init(fromAccount: Account.ID, toAccount: Account.ID, amount: Money) {
        self.fromAccount = fromAccount
        self.toAccount = toAccount
        self.amount = amount
    }

}
