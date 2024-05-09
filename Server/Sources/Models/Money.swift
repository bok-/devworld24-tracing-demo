
import Foundation

/// A type that represents a some of money, including the amount and currency.
public struct Money: Codable, Hashable, Sendable {

    // MARK: - Properties

    /// The amount of money
    public let amount: Decimal

    /// The currency that the amount of money is in
    public let currency: Currency


    // MARK: - Initialisation

    /// Memberwise initialiser
    public init(amount: Decimal, currency: Currency) {
        self.amount = amount
        self.currency = currency
    }

}


// MARK: - Currency

public extension Money {

    /// A list of supported currencies
    enum Currency: String, Codable, Hashable, Sendable {
        case all = "ALL"
        case dzd = "DZD"
        case ars = "ARS"
        case aud = "AUD"
        case bsd = "BSD"
        case bhd = "BHD"
        case bdt = "BDT"
        case amd = "AMD"
        case bbd = "BBD"
        case bmd = "BMD"
        case btn = "BTN"
        case bob = "BOB"
        case bwp = "BWP"
        case bzd = "BZD"
        case sbd = "SBD"
        case bnd = "BND"
        case mmk = "MMK"
        case bif = "BIF"
        case khr = "KHR"
        case cad = "CAD"
        case cve = "CVE"
        case kyd = "KYD"
        case lkr = "LKR"
        case clp = "CLP"
        case cny = "CNY"
        case cop = "COP"
        case kmf = "KMF"
        case crc = "CRC"
        case hrk = "HRK"
        case cup = "CUP"
        case czk = "CZK"
        case dkk = "DKK"
        case dop = "DOP"
        case svc = "SVC"
        case etb = "ETB"
        case ern = "ERN"
        case fkp = "FKP"
        case fjd = "FJD"
        case djf = "DJF"
        case gmd = "GMD"
        case gip = "GIP"
        case gtq = "GTQ"
        case gnf = "GNF"
        case gyd = "GYD"
        case htg = "HTG"
        case hnl = "HNL"
        case hkd = "HKD"
        case huf = "HUF"
        case isk = "ISK"
        case inr = "INR"
        case idr = "IDR"
        case irr = "IRR"
        case iqd = "IQD"
        case ils = "ILS"
        case jmd = "JMD"
        case jpy = "JPY"
        case kzt = "KZT"
        case jod = "JOD"
        case kes = "KES"
        case kpw = "KPW"
        case krw = "KRW"
        case kwd = "KWD"
        case kgs = "KGS"
        case lak = "LAK"
        case lbp = "LBP"
        case lsl = "LSL"
        case lrd = "LRD"
        case lyd = "LYD"
        case ltl = "LTL"
        case mop = "MOP"
        case mwk = "MWK"
        case myr = "MYR"
        case mvr = "MVR"
        case mro = "MRO"
        case mur = "MUR"
        case mxn = "MXN"
        case mnt = "MNT"
        case mdl = "MDL"
        case mad = "MAD"
        case omr = "OMR"
        case nad = "NAD"
        case npr = "NPR"
        case ang = "ANG"
        case awg = "AWG"
        case vuv = "VUV"
        case nzd = "NZD"
        case nio = "NIO"
        case ngn = "NGN"
        case nok = "NOK"
        case pkr = "PKR"
        case pab = "PAB"
        case pgk = "PGK"
        case pyg = "PYG"
        case pen = "PEN"
        case php = "PHP"
        case qar = "QAR"
        case rub = "RUB"
        case rwf = "RWF"
        case shp = "SHP"
        case std = "STD"
        case sar = "SAR"
        case scr = "SCR"
        case sll = "SLL"
        case sgd = "SGD"
        case vnd = "VND"
        case sos = "SOS"
        case zar = "ZAR"
        case ssp = "SSP"
        case szl = "SZL"
        case sek = "SEK"
        case chf = "CHF"
        case syp = "SYP"
        case thb = "THB"
        case top = "TOP"
        case ttd = "TTD"
        case aed = "AED"
        case tnd = "TND"
        case ugx = "UGX"
        case mkd = "MKD"
        case egp = "EGP"
        case gbp = "GBP"
        case tzs = "TZS"
        case usd = "USD"
        case uyu = "UYU"
        case uzs = "UZS"
        case wst = "WST"
        case yer = "YER"
        case twd = "TWD"
        case cuc = "CUC"
        case zwl = "ZWL"
        case tmt = "TMT"
        case ghs = "GHS"
        case vef = "VEF"
        case sdg = "SDG"
        case uyi = "UYI"
        case rsd = "RSD"
        case mzn = "MZN"
        case azn = "AZN"
        case ron = "RON"
        case che = "CHE"
        case chw = "CHW"
        case `try` = "TRY"
        case xaf = "XAF"
        case xcd = "XCD"
        case xof = "XOF"
        case xpf = "XPF"
        case xba = "XBA"
        case xbb = "XBB"
        case xbc = "XBC"
        case xbd = "XBD"
        case xau = "XAU"
        case xdr = "XDR"
        case xag = "XAG"
        case xpt = "XPT"
        case xpd = "XPD"
        case xua = "XUA"
        case zmw = "ZMW"
        case srd = "SRD"
        case mga = "MGA"
        case cou = "COU"
        case afn = "AFN"
        case tjs = "TJS"
        case aoa = "AOA"
        case byr = "BYR"
        case bgn = "BGN"
        case cdf = "CDF"
        case bam = "BAM"
        case eur = "EUR"
        case mxv = "MXV"
        case uah = "UAH"
        case gel = "GEL"
        case bov = "BOV"
        case pln = "PLN"
        case brl = "BRL"
        case clf = "CLF"
        case xsu = "XSU"
        case usn = "USN"
    }

}

// MARK: - Comparable

extension Money: Comparable {

    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(lhs.currency == rhs.currency)
        return lhs.amount < rhs.amount
    }

}


// MARK: - Math

public extension Money {

    /// Adds two Money values and produces their sum.
    ///
    /// BOTH CURRENCIES MUST BE THE SAME.
    ///
    static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency)
        return Money(amount: lhs.amount + rhs.amount, currency: lhs.currency)
    }

    /// Adds two Money values and stores the result in the left-hand-side variable.
    ///
    /// BOTH CURRENCIES MUST BE THE SAME.
    ///
    static func += (lhs: inout Money, rhs: Money) {
        lhs = lhs + rhs
    }

    /// Subtracts one Money value from another and produces their difference.
    ///
    /// BOTH CURRENCIES MUST BE THE SAME.
    ///
    static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currency == rhs.currency)
        return Money(amount: lhs.amount - rhs.amount, currency: lhs.currency)
    }

    /// Subtracts the second Money value from the first and stores the difference in the
    /// left-hand-side variable.
    ///
    /// BOTH CURRENCIES MUST BE THE SAME.
    ///
    static func -= (lhs: inout Money, rhs: Money) {
        lhs = lhs - rhs
    }

    /// Returns the additive inverse of this Money value.
    ///
    /// The result is always exact.
    ///
    func negating() -> Money {
        Money(amount: amount * -1, currency: currency)
    }

    /// Replaces this value with its additive inverse.
    ///
    /// The result is always exact.
    ///
    mutating func negate() {
        self = negating()
    }

}
