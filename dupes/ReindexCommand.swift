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
        return DupesDatabase.open(options.db.path)
            .tryPassthrough { db in
                try db.reIndex(duplicatesOnly: !options.allFiles)
            }
            .tryPassthrough { db in
                if options.hash {
                    try HashCommand.run(db)
                }
            }
            .tryMap { db in
                // Since we're housekeeping, try to free up space and reduce fragmentation
                do { try db.vacuum(force: true) } catch {}
            }
    }
}

struct ReindexCommandOptions: OptionsType {
    let db: DatabaseOptions
    let hash: Bool
    let allFiles: Bool

    static func create(db: DatabaseOptions) -> Bool -> Bool -> ReindexCommandOptions {
        return { hash in { allFiles in
            ReindexCommandOptions(db: db, hash: hash, allFiles: allFiles)
        } }
    }

    static func evaluate(m: CommandMode) -> Result<ReindexCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Option(key: "hash", defaultValue: false, usage: "Hash the potential duplicates after reindexing")
            <*> m <| Switch(flag: "a", key: "all", usage: "Scan all indexed files, not just duplicates")
    }
}
