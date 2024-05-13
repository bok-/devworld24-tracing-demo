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

import OTel

/// A supplier or business that a customer has purchased something from
public struct Merchant: Codable, Hashable, Identifiable, Sendable {

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
    public init(id: String, name: String, address: String?, location: Location?, logoURL: String, updatedBy: OTelSpanContext?) {
        self.id = id
        self.name = name
        self.address = address
        self.location = location
        self.logoURL = logoURL
        self.updatedBy = updatedBy
    }

}

// MARK: - Location

public extension Merchant {

    /// A geographic location for a Merchant
    enum Location: Codable, Hashable, Sendable {
        case coordinate(latitude: Double, longitude: Double)
    }

}
