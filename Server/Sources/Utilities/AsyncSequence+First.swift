
public extension AsyncSequence {

    /// Returns the first element the AsyncSequence emits and completes
    func first() async throws -> Element? {
        try await first(where: { _ in true })
    }

}
