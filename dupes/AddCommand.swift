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
        return DupesDatabase.open(options.db.path).tryMap { db in
            for rawPath in readLines() {
                let path = Path(rawPath).absolute()
                try addFile(path, db: db)
            }

            if options.hash {
                try db.hashAllCandidates()
            }
        }
    }
}

struct AddCommandOptions: OptionsType {
    let db: DatabaseOptions
    let hash: Bool

    static func create(dbOptions: DatabaseOptions) -> Bool -> AddCommandOptions {
        return { hash in
            AddCommandOptions(db: dbOptions, hash: hash)
        }
    }

    static func evaluate(m: CommandMode) -> Result<AddCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Option(key: "hash", defaultValue: false, usage: "Hash the potential duplicates in the database after adding the files")
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
