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

/// A button that runs an async action. It can optionally show progrress and error states.
struct AsyncButton<Label: View>: View {

    // MARK: - Properties

    var action: () async throws -> Void
    var actionOptions = Set(ActionOption.allCases)
    var label: () -> Label

    @State private var isDisabled = false
    @State private var showProgressView = false

    @State private var showError = false
    @State private var error: Error?


    // MARK: - Initialisation

    init(
        action: @escaping () async throws -> Void,
        actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.actionOptions = actionOptions
        self.label = label
    }

    init(
        @ViewBuilder label: @escaping () -> Label,
        actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
        action: @escaping () async throws -> Void
    ) {
        self.action = action
        self.actionOptions = actionOptions
        self.label = label
    }

    init(
        _ string: @autoclosure @escaping () -> String,
        actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
        action: @escaping () async throws -> Void
    ) where Label == Text {
        self.action = action
        self.actionOptions = actionOptions
        self.label = { Text(string()) }
    }


    // MARK: - View Body

    var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }

                Task {
                    do {
                        var progressViewTask: Task<Void, Error>?

                        if actionOptions.contains(.showProgressView) {
                            progressViewTask = Task {
                                try await Task.sleep(nanoseconds: 150_000_000)
                                showProgressView = true
                            }
                        }

                        try await action()
                        progressViewTask?.cancel()

                        isDisabled = false
                        showProgressView = false
                        showError = false
                        error = nil

                    } catch {
                        isDisabled = false
                        showProgressView = false
                        showError = true
                        self.error = error
                    }
                }
            },
            label: {
                ZStack {
                    label().opacity(showProgressView ? 0 : 1)

                    if showProgressView {
                        ProgressView()
                    }
                }
            }
        )
        .disabled(isDisabled)
        .alert(
            "Uh oh",
            isPresented: $showError,
            actions: {
                Button("OK") {
                    isDisabled = false
                    showProgressView = false
                    showError = false
                    error = nil
                }

            },
            message: {
                Text(error?.localizedDescription ?? "Unknown error.")
            }
        )

    }
}


// MARK: - Options

extension AsyncButton {
    enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}
