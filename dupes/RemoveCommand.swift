//
//  RemoveCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant
import PathKit

struct RemoveCommand: CommandProtocol {
    let verb = "remove"
    let function = "Unindex files passed in on standard input"

    func run(_ options: DatabaseOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.path).tryMap { db in
            for rawPath in readLines() {
                let path = Path(rawPath).absolute()
                _ = try db.removeFileRecord(filePath: "\(path)")
            }
        }
    }
}
