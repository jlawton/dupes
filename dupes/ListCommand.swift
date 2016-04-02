//
//  ListCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

extension DupesDatabase {
    func listDuplicates(indent: String = "", bare: Bool = false, separator: String = "\n") throws -> AnySequence<String> {
        let groupedSequence = try groupedDuplicates()
        return AnySequence {
            return groupedSequence.lazy.map({ files in
                let s = bare ? "" : "\(indent)[Files of size \(human(files[0].size))]\(separator)"
                return s + files.map({ "\(indent)\($0.path)" }).joinWithSeparator(separator)
            }).generate()
        }
    }
}

struct ListCommand: CommandType {
    typealias Options = ListCommandOptions

    let verb = "list"
    let function = "List all duplicates"

    func run(options: ListCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap({ try ListCommand.run($0, bare: options.bare, fileSeparator: options.fileSeparator) })
    }

    static func run(db: DupesDatabase, bare: Bool = false, fileSeparator: String = "\n", groupSeparator optionalGroupSeparator: String? = nil) throws {
        var first = true
        let groupSeparator = optionalGroupSeparator ?? "\(fileSeparator)\(fileSeparator)"
        for group in try db.listDuplicates("", bare: bare, separator: fileSeparator) {
            if first { first = false }
            else { print(groupSeparator, separator: "", terminator: "") }
            print(group, separator: "", terminator: "")
        }
    }
}

struct ListCommandOptions: OptionsType {
    let dbPath: String
    let bare: Bool
    let fileSeparator: String

    static func create(dbPath: String) -> Bool -> Bool -> ListCommandOptions {
        return { bare in { nulSeparator in
            let fileSeparator = nulSeparator ? "\0" : "\n"
            return ListCommandOptions(dbPath: dbPath,
                bare: (bare || nulSeparator),
                fileSeparator: fileSeparator)
        } }
    }

    static func evaluate(m: CommandMode) -> Result<ListCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
            <*> m <| Switch(flag: nil, key: "bare", usage: "Display grouped file paths without summary data")
            <*> m <| Switch(flag: "0", key: "print0", usage: "Separate files with NUL characters, rather than by line. Implies --bare")
    }
}
