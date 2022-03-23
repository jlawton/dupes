//
//  VersionCommand.swift
//  dupes
//
//  Created by James Lawton on 3/30/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

let dupesVersion = "0.1.0"

struct VersionCommand: CommandProtocol {
    let verb = "version"
    let function = "Display the current version of dupes"

    func run(_ options: NoOptions<DupesError>) -> Result<(), DupesError> {
        print(dupesVersion)
        return Result(value: ())
    }
}
