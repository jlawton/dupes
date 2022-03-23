//
//  SummaryCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

struct SummaryCommand: CommandProtocol {
    let verb = "summary"
    let function = "Display summary of duplicates"

    func run(_ options: SummaryCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).tryMap { db in
            try db.duplicateStats()
        }
    }
}

struct SummaryCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let allFiles: Bool

    static func create(db: DatabaseOptions) -> (Bool) -> SummaryCommandOptions {
        return { allFiles in
            SummaryCommandOptions(db: db, allFiles: allFiles)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<SummaryCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Option(key: "all", defaultValue: false, usage: "Scan all indexed files, not just duplicates")
    }
}
