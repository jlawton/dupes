//
//  HashCommand.swift
//  dupes
//
//  Created by James Lawton on 3/30/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct HashCommand: CommandType {
    typealias Options = HashCommandOptions

    let verb = "hash"
    let function = "Hash all indexed files that might be duplicates"

    func run(options: HashCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap { db in
            try db.hashAllCandidates()
        }
    }
}

struct HashCommandOptions: OptionsType {
    let dbPath: String

    static func create(dbPath: String) -> HashCommandOptions {
        return HashCommandOptions(dbPath: dbPath)
    }

    static func evaluate(m: CommandMode) -> Result<HashCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
    }
}
