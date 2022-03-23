//
//  HashCommand.swift
//  dupes
//
//  Created by James Lawton on 3/30/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

struct HashCommand: CommandProtocol {
    let verb = "hash"
    let function = "Hash all indexed files that might be duplicates"

    func run(_ options: DatabaseOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.path).tryMap(HashCommand.run)
    }

    static func run(db: DupesDatabase) throws {
        return try db.hashAllCandidates()
    }
}
