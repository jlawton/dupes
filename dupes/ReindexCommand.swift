//
//  ReindexCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct ReindexCommand: CommandType {
    let verb = "reindex"
    let function = "Unindex all deleted duplicates and unhash changed duplicates"

    func run(options: ReindexCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).tryMap { db in
            try db.reIndex(duplicatesOnly: !options.allFiles)
        }
    }
}

struct ReindexCommandOptions: OptionsType {
    let db: DatabaseOptions
    let allFiles: Bool

    static func create(db: DatabaseOptions) -> Bool -> ReindexCommandOptions {
        return { allFiles in
            ReindexCommandOptions(db: db, allFiles: allFiles)
        }
    }

    static func evaluate(m: CommandMode) -> Result<ReindexCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Switch(flag: "a", key: "all", usage: "Scan all indexed files, not just duplicates")
    }
}
