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
import SwiftUI
import Tracing

private enum TracerEnvironmentKey: EnvironmentKey {
    static var defaultValue: any Tracer {
        NoOpTracer()
    }
}

extension EnvironmentValues {

    /// Access to the current tracer
    var tracer: any Tracer {
        get { self[TracerEnvironmentKey.self] }
        set { self[TracerEnvironmentKey.self] = newValue }
    }

}
