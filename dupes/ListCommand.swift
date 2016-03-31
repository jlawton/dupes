//
//  ListCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

extension DupesDatabase {
    func listDuplicates(indent: String = "") throws -> AnySequence<String> {
        let groupedSequence = try groupedDuplicates()
        return AnySequence {
            return groupedSequence.lazy.map({ files in
                let s = "\(indent)[Files of size \(human(files[0].size))]\n"
                return s + files.map({ "\(indent)\($0.path)" }).joinWithSeparator("\n")
            }).generate()
        }
    }
}

struct ListCommand: CommandType {
    typealias Options = ListCommandOptions

    let verb = "list"
    let function = "List all duplicates"

    func run(options: ListCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap { db in
            var first = true
            for group in try db.listDuplicates() {
                if first { first = false }
                else { print("") }
                print(group)
            }
        }
    }
}

struct ListCommandOptions: OptionsType {
    let dbPath: String

    static func create(dbPath: String) -> ListCommandOptions {
        return ListCommandOptions(dbPath: dbPath)
    }

    static func evaluate(m: CommandMode) -> Result<ListCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
    }
}
