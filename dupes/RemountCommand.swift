//
//  RemountCommand.swift
//  dupes
//
//  Created by James Lawton on 4/1/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct RemountCommand: CommandType {
    let verb = "remount"
    let function = "Change the directory prefix of files in the dupes database"

    func run(options: RemountCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).tryMap { db in
            let moved = try db.remount(options.fromPath, to: options.toPath)
            print("Remounted \(moved) files")
            return ()
        }
    }
}

struct RemountCommandOptions: OptionsType {
    let db: DatabaseOptions
    let fromPath: String
    let toPath: String

    static func create(db: DatabaseOptions) -> String -> String -> RemountCommandOptions {
        return { fromPath in { toPath in
            RemountCommandOptions(db: db, fromPath: fromPath, toPath: toPath)
        } }
    }

    static func evaluate(m: CommandMode) -> Result<RemountCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> m <| Argument(usage: "Old ount point")
            <*> m <| Argument(usage: "New mount point")
    }
}
