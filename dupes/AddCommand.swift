//
//  AddCommand.swift
//  dupes
//
//  Created by James Lawton on 3/29/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

let databaseOption = Option(key: "db", defaultValue: defaultDatabasePath, usage: "Use the specified database file")

struct AddCommand: CommandType {
    let verb = "add"
    let function = "Index files passed in on standard input"

    func run(options: AddCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path)
            .tryPassthrough({ try AddCommand.run($0, filePaths: options.filePaths) })
            .tryMap { db in
                if options.hash {
                    try HashCommand.run(db)
                }
            }
    }

    static func run(db: DupesDatabase, filePaths: [String]? = nil) throws {
        let files = (filePaths != nil)
            ? AnySequence { filePaths!.generate() }
            : readLines()

        for rawPath in files {
            let path = Path(rawPath).absolute()
            try addFile(path, db: db)
        }
    }
}

struct AddCommandOptions: OptionsType {
    let db: DatabaseOptions
    let hash: Bool
    let filePaths: [String]?

    static func create(dbOptions: DatabaseOptions) -> Bool -> [String] -> AddCommandOptions {
        return { hash in { paths in
            let filePaths: [String]? = (paths.count > 0) ? paths : nil
            return AddCommandOptions(db: dbOptions, hash: hash, filePaths: filePaths)
        } }
    }

    static func evaluate(m: CommandMode) -> Result<AddCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Option(key: "hash", defaultValue: false, usage: "Hash the potential duplicates in the database after adding the files")
            <*> m <| Argument(defaultValue: [], usage: "Files to index, rather than reading from standard input")
    }
}

func addFile(path: Path, db: DupesDatabase) throws {
    guard path.isFile else {
        printErr("Not a file: \(path)")
        return
    }

    if let fileRecord = FileRecord.fromFileAtPath("\(path)") {
        printErr("Adding: \(path)")
        try db.addFileRecord(fileRecord)
    } else {
        printErr("Failed to get file size: \(path)")
    }
}
