//
//  Options.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

let defaultDatabasePath = "~/.dupes.db"

struct DatabaseOptions: OptionsType {
    let path: String

    static func create(path: String) -> DatabaseOptions {
        return DatabaseOptions(path: path)
    }

    static func evaluate(m: CommandMode) -> Result<DatabaseOptions, CommandantError<DupesError>> {
        return create
            <*> m <| Option(key: "db", defaultValue: defaultDatabasePath, usage: "Use the specified database file")
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

struct FileArguments: OptionsType {
    private let givenFilePaths: [String]?

    var filesPaths: AnySequence<String> {
        let files = (givenFilePaths != nil)
            ? AnySequence { self.givenFilePaths!.generate() }
            : readLines()
        return files
    }

    static func create(filePaths paths: [String]) -> FileArguments {
        let filePaths: [String]? = (paths.count > 0) ? paths : nil
        return FileArguments(givenFilePaths: filePaths)
    }

    static func evaluate(m: CommandMode) -> Result<FileArguments, CommandantError<DupesError>> {
        return create
            <*> m <| Argument(defaultValue: [], usage: "Files to index, rather than reading from standard input")
    }
}

private func recursiveEnumerator(path: String) -> AnySequence<String>? {
    let fileManager = NSFileManager.defaultManager()

    var isDirectory: ObjCBool = false
    guard fileManager.fileExistsAtPath(path, isDirectory: &isDirectory) else {
        return nil
    }

    if isDirectory {
        return AnySequence { fileManager.generatorAtPath(path) }
    } else {
        return AnySequence { [ path ].generate() }
    }
}

extension NSFileManager {
    func generatorAtPath(path: String) -> AnyGenerator<String> {
        let enumerator = enumeratorAtPath(path)!
        return AnyGenerator { enumerator.nextObject() as? String }
    }
}
