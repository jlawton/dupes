//
//  SummaryCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct SummaryCommand: CommandType {
    typealias Options = SummaryCommandOptions

    let verb = "summary"
    let function = "Display summary of duplicates"

    func run(options: SummaryCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap { db in
            try db.duplicateStats()
        }
    }
}

struct SummaryCommandOptions: OptionsType {
    let dbPath: String
    let allFiles: Bool

    static func create(dbPath: String) -> Bool -> SummaryCommandOptions {
        return { allFiles in
            SummaryCommandOptions(dbPath: dbPath, allFiles: allFiles)
        }
    }

    static func evaluate(m: CommandMode) -> Result<SummaryCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
            <*> m <| Option(key: "all", defaultValue: false, usage: "Scan all indexed files, not just duplicates")
    }
}
