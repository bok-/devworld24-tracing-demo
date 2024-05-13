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

public enum IdentifiedDifference<Element> where Element: Hashable & Identifiable {

    case inserted(Element)
    case removed(Element)
    case changed(Element)

}

public extension Collection where Element: Hashable & Identifiable {

    /// Calculates and returns an array of the differences between `self` and `other`. Unlike the normal `differences`
    /// methods from the Standard library return differences when an element identified by `Self.id` has changed
    /// (ie its no longer equal to the other element with the same ID).
    ///
    /// It does not detect changes in index/offsets between the collections, just presence.
    ///
    /// - Note: If an element with the same ID appears more than once in the collection the behaviour is undefined.
    ///
    func identifiedDifference(from other: Self) -> [IdentifiedDifference<Element>] {
        var differences = [IdentifiedDifference<Element>]()

        // Walk self, comparing it against elements in other
        for element in self {
            if let otherElement = other.first(where: { $0.id == element.id }) {
                if otherElement != element {
                    differences.append(.changed(element))           // It changed since other
                }
            } else {
                differences.append(.inserted(element))              // Not found, must have been inserted
            }
        }

        // Walk other, check for things that no longer exist in self
        for element in other {
            if first(where: { $0.id == element.id }) == nil {
                differences.append(.removed(element))               // It no longer exists, must have been removed
            }
        }

        return differences
    }

}
