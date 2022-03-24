//
//  AddCommand.swift
//  dupes
//
//  Created by James Lawton on 3/29/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant
import PathKit

struct AddCommand: CommandProtocol {
    let verb = "add"
    let function = "Index files passed in on standard input"

    func run(_ options: AddCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path)
            .tryPassthrough({ try AddCommand.run(db: $0, filePaths: options.files.filesPaths) })
            .tryMap { db in
                if options.hash {
                    try HashCommand.run(db: db, options: options.hashOptions)
                }
            }
    }

    static func run(db: DupesDatabase, filePaths: AnySequence<String>) throws {
        for rawPath in filePaths {
            let path = Path(rawPath).absolute()
            try addFile(path: path, db: db)
        }
    }
}

struct AddCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let hash: Bool
    let hashOptions: HashOptions
    let files: FileArguments

    static func create(dbOptions: DatabaseOptions) -> (Bool) -> (HashOptions) -> (FileArguments) -> AddCommandOptions {
        return { hash in { hashOptions in { files in
            return AddCommandOptions(db: dbOptions, hash: hash, hashOptions: hashOptions, files: files)
        } } }
    }

    static func evaluate(_ m: CommandMode) -> Result<AddCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Option(key: "hash", defaultValue: false, usage: "Hash the potential duplicates in the database after adding the files")
            <*> HashOptions.evaluate(m)
            <*> FileArguments.evaluate(m)
    }
}

func addFile(path: Path, db: DupesDatabase) throws {
    guard path.isFile else {
        printErr("Not a file: \(path)")
        return
    }

    if let fileRecord = FileRecord.fromFile(atPath: "\(path)") {
        printErr("Adding: \(path)")
        try db.addFileRecord(fileRecord)
    } else {
        printErr("Failed to get file size: \(path)")
    }
}
