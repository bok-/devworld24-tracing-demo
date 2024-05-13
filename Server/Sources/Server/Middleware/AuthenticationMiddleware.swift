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

import HTTPTypes
import Hummingbird
import Models
import Tracing

/// A middleware that authenticates incoming API requests by checking for the presence of a X-BokBank-User-ID token.
///
/// This middleware can be evolved to support actual authentication once we have any.
///
struct AuthenticationMiddleware: RouterMiddleware {

    func handle(
        _ input: Request,
        context: BokRequestContext,
        next: (Request, BokRequestContext) async throws -> Response
    ) async throws -> Response {
        // TODO: Add some security or something
        guard let userID = input.headers[.userID] else {
            throw HTTPError(.unauthorized)
        }

        if let span = context.span {
            span.updateAttributes {
                $0["enduser.id"] = userID
            }
        }

        var copy = context
        copy.userID = userID
        return try await next(input, copy)
    }

}


// MARK: - Headers

extension HTTPField.Name {
    static var userID: Self { .init("X-BokBank-User-ID")! }
}
