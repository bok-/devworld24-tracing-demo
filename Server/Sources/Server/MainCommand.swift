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

import ArgumentParser

@main
struct MainCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "The main highly distributed and highly available (and highly secure) BokBank backend",
        subcommands: [
            ServeCommand.self,
        ],
        defaultSubcommand: ServeCommand.self
    )

}
