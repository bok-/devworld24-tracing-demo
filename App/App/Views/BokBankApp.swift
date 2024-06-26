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

import Core
import Models
import SwiftUI

@main
struct BokBankApp: App {

    // MARK: - State

    private var appCore: AppCore = {
        let core = try! AppCore(
            userID: "demo",     // TODO: Add login support
            endpoint: Endpoint(scheme: "http", host: "localhost", port: 2265)
        )
        Task.detached {
            await core.startSync()
        }
        return core
    }()

    @State var viewModel: ContentViewModel

    @Environment(\.scenePhase) private var scenePhase


    // MARK: - Initialisation

    init() {
        self.viewModel = ContentViewModel(appCore: appCore)
    }


    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: viewModel)
                    .environment(\.tracer, appCore.tracer)
                    .environmentObject(appCore)
                    .onChange(of: scenePhase) { oldValue, newValue in
                        guard oldValue.isInForeground != newValue.isInForeground else {
                            return
                        }
                        Task.detached {
                            if newValue.isInForeground {
                                await appCore.startSync()
                            } else {
                                await appCore.cancelSync()
                            }
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private extension ScenePhase {
    var isInForeground: Bool {
        self == .active || self == .inactive
    }
}
