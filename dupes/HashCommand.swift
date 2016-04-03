//
//  HashCommand.swift
//  dupes
//
//  Created by James Lawton on 3/30/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct HashCommand: CommandType {
    let verb = "hash"
    let function = "Hash all indexed files that might be duplicates"

    func run(options: DatabaseOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.path).tryMap { db in
            try db.hashAllCandidates()
        }
    }
}
