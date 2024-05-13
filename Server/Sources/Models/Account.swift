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

/// A representation of a bank account
public struct Account: Codable, Hashable, Identifiable, Sendable {

    // MARK: - Properties

    /// Primary key
    public let id: String

    /// Bank-State-Branch code
    public let bsb: String

    /// Main account number
    public let number: String

    /// Display name for the account
    public let name: String

    /// Current amount of money held in the account
    public let balance: Money

    /// The type of product. eg transacting account or savings account
    public let product: Product

    /// The source span that updated this model.
    /// This is used to associate spans where subscribers receive updated models with the trace that changed the model.
    public let updatedBy: OTelSpanContext?

    /// Our supported products
    public enum Product: Codable, Hashable, Sendable {
        case transacting
        case savings
    }


    // MARK: - Initialisation

    /// Memberwise initialiser
    public init(id: String, bsb: String, number: String, name: String, product: Product, balance: Money, updatedBy: OTelSpanContext?) {
        self.id = id
        self.bsb = bsb
        self.number = number
        self.name = name
        self.product = product
        self.balance = balance
        self.updatedBy = updatedBy
    }

}
