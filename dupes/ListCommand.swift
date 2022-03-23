//
//  ListCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

extension DupesDatabase {
    func listDuplicates(indent: String = "", bare: Bool = false, separator: String = "\n") throws -> AnySequence<String> {
        let groupedSequence = try groupedDuplicates()
        return AnySequence(
            groupedSequence.lazy.map({ files in
                let s = bare ? "" : "\(indent)[Files of size \(human(files[0].size))]\(separator)"
                return s + files.map({ "\(indent)\($0.path)" }).joined(separator: separator)
            })
        )
    }
}

struct ListCommand: CommandProtocol {
    let verb = "list"
    let function = "List all duplicates"

    func run(_ options: ListCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).tryMap({ try ListCommand.run(db: $0, options: options.list) })
    }

    static func run(db: DupesDatabase, options: ListOptions) throws {
        var first = true
        for group in try db.listDuplicates(indent: "", bare: options.bare, separator: options.fileSeparator) {
            if first { first = false }
            else { print(options.groupSeparator, separator: "", terminator: "") }
            print(group, separator: "", terminator: "")
        }
    }
}

struct ListCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let list: ListOptions

    static func create(db: DatabaseOptions) -> (ListOptions) -> ListCommandOptions {
        return { list in
            return ListCommandOptions(db: db, list: list)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<ListCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> ListOptions.evaluate(m)
    }
}
