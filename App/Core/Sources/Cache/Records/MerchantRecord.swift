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

import GRDB
import Models

public final class MerchantRecord: Codable, PersistableRecord, FetchableRecord {

    // MARK: - Properties

    let id: String
    let name: String
    let address: String?
    let location: Location?
    let logoURL: String


    // MARK: - Initialisation

    /// Memberwise initialiser
    init(
        id: String,
        name: String,
        address: String?,
        location: Location?,
        logoURL: String
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.location = location
        self.logoURL = logoURL
    }

}

extension MerchantRecord {

    enum Location: Codable {
        case coordinate(latitude: Double, longitude: Double)
    }

}

// MARK: - TableRecord Conformance

extension MerchantRecord {

    public static var databaseTableName: String {
        "merchant"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let address = Column(CodingKeys.address)
        static let location = Column(CodingKeys.location)
        static let logoURL = Column(CodingKeys.logoURL)
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
            updatedBy: nil
        )
    }
}

public extension MerchantRecord {
    convenience init(_ merchant: Merchant) {
        self.init(
            id: merchant.id,
            name: merchant.name,
            address: merchant.address,
            location: merchant.location.map { .init($0) },
            logoURL: merchant.logoURL
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
