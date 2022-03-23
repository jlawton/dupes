//
//  RunCommand.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

struct RunCommand: CommandProtocol {
    let verb = "run"
    let function = "Add files from standard input and list duplicates"

    func run(_ options: RunCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path)
            .tryPassthrough({ try AddCommand.run(db: $0, filePaths: options.files.filesPaths) })
            .tryPassthrough(HashCommand.run)
            .flatMap { db in
                if options.interactive {
                    // Reopen STDIN to the TTY because we expect to have been
                    // attached to a pipe to add files.
                    return InteractiveCommand.run(db: db, deleteOptions: options.delete, reopenTTY: true)
                } else {
                    return Result<DupesDatabase, DupesError>.success(db)
                        .tryMap { try ListCommand.run(db: $0, options: options.list) }
                }
            }
    }
}

struct RunCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let list: ListOptions
    let interactive: Bool
    let delete: DeleteOptions
    let files: FileArguments

    static func create(db: DatabaseOptions) -> (ListOptions) -> (Bool) -> (DeleteOptions) -> (FileArguments) -> RunCommandOptions {
        return { list in { interactive in { delete in { files in
            RunCommandOptions(db: db, list: list, interactive: interactive, delete: delete, files: files)
        } } } }
    }

    static func evaluate(_ m: CommandMode) -> Result<RunCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> ListOptions.evaluate(m)
            <*> m <| Switch(flag: nil, key: "interactive", usage: "Use interactive mode instead of list mode")
            <*> DeleteOptions.evaluate(m)
            <*> FileArguments.evaluate(m)
    }
}
