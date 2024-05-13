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

import SwiftUI

struct ResultView<Success, Failure, SuccessContent, FailureContent>: View where Failure: Error, SuccessContent: View, FailureContent: View {

    // MARK: - Properties

    private let result: Result<Success, Failure>
    private let successContent: (Success) -> SuccessContent
    private let failureContent: (Failure) -> FailureContent


    // MARK: - Initialisation

    init(
        _ result: Result<Success, Failure>,
        @ViewBuilder success: @escaping (Success) -> SuccessContent,
        @ViewBuilder failure: @escaping (Error) -> FailureContent
    ) {
        self.result = result
        self.successContent = success
        self.failureContent = failure
    }


    // MARK: - View Body

    var body: some View {
        switch result {
        case let .success(value):
            successContent(value)
        case let .failure(error):
            failureContent(error)
        }
    }

}


// MARK: - Generic Errors

extension ResultView where FailureContent == Text {

    init(
        _ result: Result<Success, Failure>,
        @ViewBuilder success: @escaping (Success) -> SuccessContent
    ) {
        self.init(result, success: success) { error in
            Text(error.localizedDescription)
        }
    }

}
