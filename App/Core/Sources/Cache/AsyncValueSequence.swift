
import GRDB

/// A type-erased sequence that emits database values.
///
/// This is solely because we don't want to expose GRDB types outside of this package. Probably unnecessary.
///
public struct AsyncValueSequence<Element>: AsyncSequence {

    public typealias Element = Element

    let base: AsyncValueObservation<Element>

    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeAsyncIterator())
    }

    public struct Iterator: AsyncIteratorProtocol {

        var base: AsyncValueObservation<Element>.Iterator

        public mutating func next() async throws -> Element? {
            try await base.next()
        }
    }

}
