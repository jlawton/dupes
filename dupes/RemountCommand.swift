//
//  RemountCommand.swift
//  dupes
//
//  Created by James Lawton on 4/1/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct RemountCommand: CommandType {
    typealias Options = RemountCommandOptions

    let verb = "remount"
    let function = "Change the directory prefix of files in the dupes database"

    func run(options: RemountCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap { db in
            let moved = try db.remount(options.fromPath, to: options.toPath)
            print("Remounted \(moved) files")
            return ()
        }
    }
}

struct RemountCommandOptions: OptionsType {
    let dbPath: String
    let fromPath: String
    let toPath: String

    static func create(dbPath: String) -> String -> String -> RemountCommandOptions {
        return { fromPath in { toPath in
            RemountCommandOptions(dbPath: dbPath, fromPath: fromPath, toPath: toPath)
        } }
    }

    static func evaluate(m: CommandMode) -> Result<RemountCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
            <*> m <| Argument(usage: "Old ount point")
            <*> m <| Argument(usage: "New mount point")
    }
}
