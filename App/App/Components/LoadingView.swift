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

/// A view wrapper which alternatives between two views depending on whether its nil or not.
struct LoadingView<Value, LoadedContent, LoadingContent>: View where LoadedContent: View, LoadingContent: View {

    // MARK: - Properties

    private let value: Value?
    private let loadedContent: (Value) -> LoadedContent
    private let loadingContent: () -> LoadingContent



    // MARK: - Initialisation

    init(
        _ value: Value?,
        @ViewBuilder loaded: @escaping (Value) -> LoadedContent,
        @ViewBuilder loading: @escaping () -> LoadingContent
    ) {
        self.value = value
        self.loadedContent = loaded
        self.loadingContent = loading
    }


    // MARK: - View Body

    @ViewBuilder
    var body: some View {
        if let value {
            loadedContent(value)
        } else {
            loadingContent()
        }
    }

}


// MARK: - Generic Spinners

extension LoadingView where LoadingContent == ProgressView<EmptyView, EmptyView> {

    init(
        _ value: Value?,
        @ViewBuilder loaded: @escaping (Value) -> LoadedContent
    ) {
        self.init(value, loaded: loaded) {
            ProgressView()
        }
    }

}
