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
