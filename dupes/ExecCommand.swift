//
//  ExecCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

struct ExecCommand: CommandProtocol {
    let verb = "exec"
    let function = "EXPERIMENTAL: Execute a command for each group of duplicates"

    func run(_ options: ExecCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).flatMap { db in
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

struct ExecCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let command: String
    let arguments: [String]

    static func create(db: DatabaseOptions) -> (String) -> ([String]) -> ExecCommandOptions {
        return { command in { args in
            ExecCommandOptions(db: db, command: command, arguments: args)
        } }
    }

    static func evaluate(_ m: CommandMode) -> Result<ExecCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Argument(usage: "command to run for each duplicates group")
            <*> m <| Argument(defaultValue: [], usage: "arguments to pass to command, before the file paths")
    }
}
