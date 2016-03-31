//
//  RemoveCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct RemoveCommand: CommandType {
    typealias Options = RemoveCommandOptions

    let verb = "remove"
    let function = "Unindex files passed in on standard input"

    func run(options: RemoveCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap { db in
            for rawPath in readLines() {
                let path = Path(rawPath).absolute()
                try db.removeFileRecord("\(path)")
            }
        }
    }
}

struct RemoveCommandOptions: OptionsType {
    let dbPath: String

    static func create(dbPath: String) -> RemoveCommandOptions {
        return RemoveCommandOptions(dbPath: dbPath)
    }

    static func evaluate(m: CommandMode) -> Result<RemoveCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
    }
}
