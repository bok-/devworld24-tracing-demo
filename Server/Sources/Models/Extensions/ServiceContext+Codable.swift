
import OTel
import Tracing

/// Allows for storing span context's in the database or sending it over the wire .Only stores a W3C "traceparent" equivalent, not any trace state.
extension OTelSpanContext: Codable {

    public var traceparent: String {
        var dict = [String: String]()
        OTelW3CPropagator().inject(self, into: &dict, using: DictionaryInjector())
        return dict["traceparent"]!
    }

    public init?(traceparent: String) {
        let dict = [ "traceparent": traceparent ]
        guard let context = try? OTelW3CPropagator().extractSpanContext(from: dict, using: DictionaryExtractor()) else {
            return nil
        }
        self = context
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(traceparent)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        let dict = [ "traceparent": string ]
        guard let context = try OTelW3CPropagator().extractSpanContext(from: dict, using: DictionaryExtractor()) else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Not a valid W3C traceparent header value."))
        }
        self = context
    }

}

private struct DictionaryExtractor: Extractor {
    typealias Carrier = [String: String]

    func extract(key: String, from carrier: [String: String]) -> String? {
        carrier[key]
    }
}

private struct DictionaryInjector: Injector {
    typealias Carrier = [String: String]

    func inject(_ value: String, forKey key: String, into carrier: inout [String: String]) {
        carrier[key] = value
    }
}
