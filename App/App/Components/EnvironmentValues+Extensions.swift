
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
