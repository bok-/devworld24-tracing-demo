
import NIOHTTP1
import OTel
import Tracing

struct HTTPHeadersInjector: Injector {

    typealias Carrier = HTTPHeaders

    func inject(_ value: String, forKey key: String, into carrier: inout HTTPHeaders) {
        carrier.replaceOrAdd(name: key, value: value)
    }

}

struct HTTPHeadersExtractor: Extractor {

    typealias Carrier = HTTPHeaders

    func extract(key: String, from carrier: HTTPHeaders) -> String? {
        carrier.first(name: key)
    }

}
