//
//  Options.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct DatabaseOptions: OptionsType {
    let path: String

    static func create(path: String) -> DatabaseOptions {
        return DatabaseOptions(path: path)
    }

    static func evaluate(m: CommandMode) -> Result<DatabaseOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
    }
}

struct ListOptions: OptionsType {
    let bare: Bool
    let fileSeparator: String

    var groupSeparator: String {
        return "\(fileSeparator)\(fileSeparator)"
    }

    static func create(bare: Bool) -> Bool -> ListOptions {
        return { nulSeparator in
            let fileSeparator = nulSeparator ? "\0" : "\n"
            return ListOptions(
                bare: (bare || nulSeparator),
                fileSeparator: fileSeparator)
        }
    }

    static func evaluate(m: CommandMode) -> Result<ListOptions, CommandantError<DupesError>> {
        return create
            <*> m <| Switch(flag: nil, key: "bare", usage: "Display grouped file paths without summary data")
            <*> m <| Switch(flag: "0", key: "print0", usage: "Separate files with NUL characters, rather than by line. Implies --bare")
    }
}
