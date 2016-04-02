//
//  ExecCommand.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

//
//  ExecCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct ExecCommand: CommandType {
    typealias Options = ExecCommandOptions

    let verb = "exec"
    let function = "EXPERIMENTAL: Execute a command for each group of duplicates"

    func run(options: ExecCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).flatMap { db in
            var groups: AnySequence<[FileRecord]>!
            do {
                groups = try db.groupedDuplicates()
            } catch {
                return Result(error: .Unknown("\(error)"))
            }

            for group in groups {
                let args = options.arguments + group.map({ $0.path })
                guard executeCommandIfExists(options.command, arguments: args) != nil else {
                    return Result(error: .Unknown("Failed to execute command"))
                }
            }

            return Result(value: ())
        }
    }
}

struct ExecCommandOptions: OptionsType {
    let dbPath: String
    let command: String
    let arguments: [String]

    static func create(dbPath: String) -> String -> [String] -> ExecCommandOptions {
        return { command in { args in
            ExecCommandOptions(dbPath: dbPath, command: command, arguments: args)
        } }
    }

    static func evaluate(m: CommandMode) -> Result<ExecCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
            <*> m <| Argument(usage: "command to run for each duplicates group")
            <*> m <| Argument(defaultValue: [], usage: "arguments to pass to command, before the file paths")
    }
}
