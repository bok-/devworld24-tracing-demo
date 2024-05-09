
import Foundation
import GRDB
import Models
import OTel
import Tracing

extension Migrations {

    /// Population of demo data
    static let demo = makeMigration(id: "demo") { userID, db in

        // We don't populate data for anyone except the demo account
        guard userID == "demo" else {
            return
        }

        // Create initial accounts
        let transacting = AccountSnapshot(
            bsb: "888-888",
            number: "999999999",
            name: "Transaction Account",
            product: .transacting,
            balance: Money(amount: 100, currency: .aud)
        )
        let savings = AccountSnapshot(
            bsb: "888-888",
            number: "999999998",
            name: "Savings Account",
            product: .savings,
            balance: Money(amount: 0, currency: .aud)
        )
        try transacting.save(db)
        try savings.save(db)

        // Create merchants
        for merchant in makeDemoMerchants() {
            try merchant.save(db)
        }

        // Create transactions
        for transaction in makeDemoTransactions(transacting: transacting, savings: savings) {
            try transaction.save(db)
        }

    }

}


// MARK: - Helpers

// It is not safe to use the normal record types in a migration —
// we need a point-in-time snapshot of the record types
private final class AccountSnapshot: Codable, PersistableRecord, FetchableRecord {

    let id: String
    let bsb: String
    let number: String
    let name: String
    let product: Product
    let balance: Money
    let updatedBy: OTelSpanContext?

    enum Product: String, Codable {
        case transacting
        case savings
    }

    init(bsb: String, number: String, name: String, product: Product, balance: Money) {
        self.id = "\(bsb)/\(number)"
        self.bsb = bsb
        self.number = number
        self.name = name
        self.product = product
        self.balance = balance
        self.updatedBy = nil
    }

    static var databaseTableName: String {
        "account"
    }

}

private final class TransactionSnapshot: Codable, PersistableRecord, FetchableRecord {

    let id: String
    let accountID: String
    let instant: Date
    let amount: Money
    let description: String
    let category: String
    let details: Details
    let updatedBy: OTelSpanContext?

    enum Details: Codable {
        case card(merchantID: String)
        case payment(fromAccount: String, toAccount: String, receiptNumber: String)
        case transfer(fromAccount: String, toAccount: String, receiptNumber: String)
    }

    init(accountID: String, instant: Date, amount: Money, description: String, category: String, details: Details) {
        self.id = UUID().uuidString
        self.accountID = accountID
        self.instant = instant
        self.amount = amount
        self.description = description
        self.category = category
        self.details = details
        self.updatedBy = nil
    }

    static var databaseTableName: String {
        "transaction"
    }

}

private final class MerchantSnapshot: Codable, PersistableRecord, FetchableRecord {

    let id: String
    let name: String
    let address: String?
    let location: Location?
    let logoURL: String
    let updatedBy: OTelSpanContext?

    enum Location: Codable {
        case coordinate(latitude: Double, longitude: Double)
    }

    init(id: String, name: String, address: String? = nil, location: Location? = nil, logoURL: String) {
        self.id = id
        self.name = name
        self.address = address
        self.location = location
        self.logoURL = logoURL
        self.updatedBy = nil
    }

    static var databaseTableName: String {
        "merchant"
    }

}


// MARK: - Demo Merchants

private func makeDemoMerchants() -> [MerchantSnapshot] {
    [
        .afterPay,
        .aldi,
        .allianz,
        .amazon,
        .anz,
        .bakersDelight,
        .bp,
        .bunnings,
        .coffeeClub,
        .coles,
        .grilld,
        .netflix,
        .originEnergy,
        .woolworths,
    ]
}

private extension MerchantSnapshot {

    static var afterPay: MerchantSnapshot {
        .init(
            id: "545C4DBF-2F40-4B92-8C0E-60E8ED8C48E4",
            name: "Afterpay",
            address: "380 Bourke St, Melbourne VIC 3001",
            location: .coordinate(latitude: -37.814280, longitude: 144.962330),
            logoURL: "https://www.afterpay.com/favicon.ico"
        )
    }

    static var aldi: MerchantSnapshot {
        .init(
            id: "288151F1-4589-498B-A603-1F0B8C278BBD",
            name: "Aldi",
            logoURL: "https://www.aldi.com.au/apple-touch-icon-180x180.png"
        )
    }

    static var allianz: MerchantSnapshot {
        .init(
            id: "B2590C17-C2CE-4705-AD5F-48FD2D549BBF",
            name: "Allianz",
            address: "360 Elizabeth St Melbourne VIC 3001",
            location: .coordinate(latitude: -37.810951, longitude: 144.961929),
            logoURL: "https://allianz.com.au/content/dam/onemarketing/system/favicon/AZ_Logo_eagle.png/_jcr_content/renditions/cq5dam.web.180.180.png"
        )
    }

    static var amazon: MerchantSnapshot {
        .init(
            id: "8237E0C8-9246-441C-8463-0FCD9972C646",
            name: "Amazon",
            logoURL: "https://www.amazon.com.au/favicon.ico"
        )
    }

    static var anz: MerchantSnapshot {
        .init(
            id: "DFDB9CBB-0BA5-4A74-924C-C8319B4DF88E",
            name: "ANZ",
            address: "833 Collins St, Docklands VIC 3008",
            location: .coordinate(latitude: -37.821557, longitude: 144.945508),
            logoURL: "https://www.anz.com.au/apps/settings/wcm/designs/commons/images/appicons/favicon-196x196.png"
        )
    }

    static var bakersDelight: MerchantSnapshot {
        .init(
            id: "CCC01172-CE0A-4B53-B583-9FDDE04A164F",
            name: "Bakers Delight",
            address: "391 Glen Huntly Rd, Elsternwick VIC 3185",
            location: .coordinate(latitude: -37.884650, longitude: 145.004820),
            logoURL: "https://dc49c1.hostroomcdn.com/wp-content/uploads/2023/08/cropped-BD-Logo-Burgundy_RGB_512px.jpeg-180x180.jpg"
        )
    }

    static var bp: MerchantSnapshot {
        .init(
            id: "DDBCD133-5876-49E7-A373-CB9C3D5BE68F",
            name: "BP",
            address: "51 Stokes St, Alice Springs NT 0870",
            location: .coordinate(latitude: -23.693670, longitude: 133.876530),
            logoURL: "https://www.bp.com/apps/settings/wcm/designs/refresh/bp/favicon.ico"
        )
    }

    static var bunnings: MerchantSnapshot {
        .init(
            id: "009DAF79-C250-4155-A369-A95C49669CDF",
            name: "Bunnings Warehouse",
            address: "71 Armadale Rd, Jandakot WA 6164",
            location: .coordinate(latitude: -32.126270, longitude: 115.868380),
            logoURL: "https://www.bunnings.com.au/static/images/favicons/apple-touch-icon.png"
        )
    }

    static var coffeeClub: MerchantSnapshot {
        .init(
            id: "7AB8BDE0-2F76-4183-8123-04197F69563D",
            name: "The Coffee Club",
            address: "8 Australia Ave, Sydney Olympic Park NSW 2127",
            location: .coordinate(latitude: -33.845450, longitude: 151.070970),
            logoURL: "https://coffeeclub.com.au/cdn/shop/files/Logo_180x180.png"
        )
    }

    static var coles: MerchantSnapshot {
        .init(
            id: "D1E3C3D9-196E-490D-BC39-F1E7998007AA",
            name: "Coles",
            address: "433 Blackburn Rd, Pinewood Shopping Centre, Mount Waverley VIC 3149",
            location: .coordinate(latitude: -37.890730, longitude: 145.144630),
            logoURL: "https://www.coles.com.au/content/dam/coles/global/icons/favicons/favicon.ico"
        )
    }

    static var grilld: MerchantSnapshot {
        .init(
            id: "AD183C38-C59D-4889-85DA-9A735B2B2BA0",
            name: "Grill'd",
            address: "217 Glenferrie Road, Malvern VIC 3144",
            location: .coordinate(latitude: -37.858911, longitude: 145.028856),
            logoURL: "https://grilld.com.au/favicon.ico"
        )
    }

    static var originEnergy: MerchantSnapshot {
        .init(
            id: "7C44E474-504F-47CE-BF59-BC2815BB19CB",
            name: "Origin Energy",
            address: "321 Exhibition St, Melbourne VIC 3000",
            location: .coordinate(latitude: -37.8086, longitude: 144.968456),
            logoURL: "https://www.originenergy.com.au/static/tal-client/favicon-96x96.png"
        )
    }

    static var netflix: MerchantSnapshot {
        .init(
            id: "5C7EF1BE-4CDD-47D7-B4B8-EC4CFA97948B",
            name: "Netflix",
            logoURL: "https://assets.nflxext.com/en_us/layout/ecweb/netflix-app-icon_152.jpg"
        )
    }

    static var woolworths: MerchantSnapshot {
        .init(
            id: "D4F2EA6C-BE99-4C3C-9765-F0A572967C31",
            name: "Woolworths",
            address: "63-93 Merchant St, Docklands VIC 3008",
            location: .coordinate(latitude: -37.820190, longitude: 144.943350),
            logoURL: "https://cdn0.woolworths.media/content/content/icon-header-logo-only.png"
        )
    }

}


// MARK: - Demo Transaction

private func makeDemoTransactions(transacting: AccountSnapshot, savings: AccountSnapshot) -> [TransactionSnapshot] {
    [
        TransactionSnapshot(
            accountID: transacting.id,
            instant: .now,
            amount: Money(amount: -133.0849, currency: .aud),
            description: "Visa Debit 9304 Origin Energy Melbourne",
            category: "Bills and Rates",
            details: .card(merchantID: MerchantSnapshot.originEnergy.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: .now,
            amount: Money(amount: 103.0049, currency: .aud),
            description: "Visa Debit 9304 Origin Energy Melbourne",
            category: "Bills and Rates",
            details: .card(merchantID: MerchantSnapshot.originEnergy.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: .now,
            amount: Money(amount: -13.5, currency: .aud),
            description: "Visa Debit Card 4321 Coffee Club Sydney",
            category: "Eating and Drinking Out",
            details: .card(merchantID: MerchantSnapshot.coffeeClub.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: .now,
            amount: Money(amount: -12.9, currency: .aud),
            description: "POS Authorization",
            category: "Eating and Drinking Out",
            details: .card(merchantID: MerchantSnapshot.grilld.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: .now,
            amount: Money(amount: -228.77, currency: .aud),
            description: "POS Authorization",
            category: "Groceries",
            details: .card(merchantID: MerchantSnapshot.woolworths.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: .now,
            amount: Money(amount: 100, currency: .aud),
            description: "Need a bit back",
            category: "Transfers",
            details: .transfer(fromAccount: savings.id, toAccount: transacting.id, receiptNumber: "123456789")
        ),

        TransactionSnapshot(
            accountID: savings.id,
            instant: .now,
            amount: Money(amount: -100, currency: .aud),
            description: "Need a bit back",
            category: "Transfers",
            details: .transfer(fromAccount: savings.id, toAccount: transacting.id, receiptNumber: "123456789")
        ),


        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -27, to: Date())!,
            amount: Money(amount: -12, currency: .aud),
            description: "DUN DUNNNN",
            category: "Entertainment",
            details: .card(merchantID: MerchantSnapshot.netflix.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: Money(amount: -20, currency: .aud),
            description: "Visa Debit Card 1234 Coffee Club Sydney",
            category: "Eating and Drinking Out",
            details: .card(merchantID: MerchantSnapshot.coffeeClub.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: Money(amount: -201, currency: .aud),
            description: "A little extra savings",
            category: "Transfers",
            details: .transfer(fromAccount: transacting.id, toAccount: savings.id, receiptNumber: "123456789")
        ),

        TransactionSnapshot(
            accountID: savings.id,
            instant: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: Money(amount: 201, currency: .aud),
            description: "A little extra savings",
            category: "Transfers",
            details: .transfer(fromAccount: transacting.id, toAccount: savings.id, receiptNumber: "123456789")
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            amount: Money(amount: -28, currency: .aud),
            description: "Payment from Nancy Lee",
            category: "Other Payments",
            details: .payment(fromAccount: "nancy.lee@email.com", toAccount: transacting.id, receiptNumber: UUID().uuidString)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            amount: Money(amount: -6.5, currency: .aud),
            description: "Mastercard Debit 5500 Bakers Delight Perth",
            category: "Groceries",
            details: .card(merchantID: MerchantSnapshot.bakersDelight.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: Money(amount: -44.16, currency: .aed),
            description: "Mastercard Debit 5536 BP Chapel St Windsor",
            category: "Transport",
            details: .card(merchantID: MerchantSnapshot.bp.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: Money(amount: 128.47, currency: .aud),
            description: "POS Authorization",
            category: "Physiotherapy",
            details: .card(merchantID: MerchantSnapshot.allianz.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: Money(amount: -16.4, currency: .aud),
            description: "Visa Debit 1234 Afterpay Sydney",
            category: "Uncategorised",
            details: .card(merchantID: MerchantSnapshot.afterPay.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            amount: Money(amount: -32.7, currency: .aud),
            description: "Visa Debit 4324 Coffee Club Sydney",
            category: "Eating and Drinking Out",
            details: .card(merchantID: MerchantSnapshot.coffeeClub.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            amount: Money(amount: -92.4, currency: .aud),
            description: "Mastercard Debit 9900 Bunnings Altona",
            category: "Home Improvements",
            details: .card(merchantID: MerchantSnapshot.bunnings.id)
        ),

        TransactionSnapshot(
            accountID: transacting.id,
            instant: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            amount: Money(amount: -52.37, currency: .aud),
            description: "Mastercard Debit 1166 Coles Sydney",
            category: "Groceries",
            details: .card(merchantID: MerchantSnapshot.coles.id)
        ),

    ]

}
