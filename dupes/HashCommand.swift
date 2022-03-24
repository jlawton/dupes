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

    func run(_ options: HashCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).tryMap({ try HashCommand.run(db: $0, options: options.hash) })
    }

    static func run(db: DupesDatabase, options: HashOptions) throws {
        switch options.hashFiles {
        case .candidates:
            return try db.hashAllCandidates()
        case .all:
            return try db.hashAllIndexed()
        }
    }
}

struct HashCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let hash: HashOptions

    static func create(db: DatabaseOptions) -> (HashOptions) -> HashCommandOptions {
        return { hash in
            return HashCommandOptions(db: db, hash: hash)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<HashCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> HashOptions.evaluate(m)
    }
}
