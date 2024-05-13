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

import CachedAsyncImage
import SwiftUI

/// A wrapper of `CachedAsyncImage` that shows an error symbol if image loading fails.
struct AsyncFailableImage: View {

    let imageURL: URL?

    var body: some View {
        CachedAsyncImage(url: imageURL) { phase in
            if phase.error != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.yellow)
            } else if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
    }

}
