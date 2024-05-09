
import GRDB
import Models
import OTel
import Tracing

final class MerchantRecord: Codable, PersistableRecord, FetchableRecord {

    // MARK: - Properties

    /// Primary key
    public let id: String

    /// The display name of the Merchant
    public let name: String

    /// The physical address of the Merchant
    public let address: String?

    /// The Merchant's location, such as coordinates. Used to drive visual representations
    public let location: Location?

    /// The URL where we can get the Merchant's logo from.
    public let logoURL: String

    /// The source span that updated this model.
    /// This is used to associate spans where subscribers receive updated models with the trace that changed the model.
    public let updatedBy: OTelSpanContext?


    // MARK: - Initialisation

    /// Memberwise initialiser
    init(
        id: String,
        name: String,
        address: String?,
        location: Location?,
        logoURL: String,
        updatedBy: OTelSpanContext?
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.location = location
        self.logoURL = logoURL
        self.updatedBy = updatedBy
    }

}

extension MerchantRecord {

    /// A geographic location for a Merchant
    enum Location: Codable {
        case coordinate(latitude: Double, longitude: Double)
    }

}

// MARK: - TableRecord Conformance

extension MerchantRecord {

    static var databaseTableName: String {
        "merchant"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let address = Column(CodingKeys.address)
        static let location = Column(CodingKeys.location)
        static let logoURL = Column(CodingKeys.logoURL)
        static let updatedBy = Column(CodingKeys.updatedBy)
    }

}


// MARK: - Bridging

extension Merchant {
    init(_ record: MerchantRecord) {
        self.init(
            id: record.id,
            name: record.name,
            address: record.address,
            location: record.location.map { .init($0) },
            logoURL: record.logoURL,
            updatedBy: record.updatedBy
        )
    }
}

extension MerchantRecord {
    convenience init(_ merchant: Merchant) {
        self.init(
            id: merchant.id,
            name: merchant.name,
            address: merchant.address,
            location: merchant.location.map { .init($0) },
            logoURL: merchant.logoURL,
            updatedBy: ServiceContext.current?.spanContext
        )
    }
}

extension Merchant.Location {
    init(_ location: MerchantRecord.Location) {
        switch location {
        case let .coordinate(latitude, longitude):
            self = .coordinate(latitude: latitude, longitude: longitude)
        }
    }
}

extension MerchantRecord.Location {
    init(_ location: Merchant.Location) {
        switch location {
        case let .coordinate(latitude, longitude):
            self = .coordinate(latitude: latitude, longitude: longitude)
        }
    }
}
