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
    private let recursive: Bool
    private let givenFilePaths: [String]?

    var filesPaths: AnySequence<String> {
        let files = (givenFilePaths != nil)
            ? AnySequence { self.givenFilePaths!.generate() }
            : readLines()

        if recursive {
            let sequence = files.lazy.flatMap(recursiveFileEnumerator)
            return AnySequence { sequence.generate() }
        }
        return files
    }

    static func create(recursive: Bool) -> [String] -> FileArguments {
        return { paths in
            let filePaths: [String]? = (paths.count > 0) ? paths : nil
            return FileArguments(recursive: recursive, givenFilePaths: filePaths)
        }
    }

    static func evaluate(m: CommandMode) -> Result<FileArguments, CommandantError<DupesError>> {
        return create
            <*> m <| Switch(flag: "r", key: "recursive", usage: "Recurse files in given directories")
            <*> m <| Argument(defaultValue: [], usage: "Files to index, rather than reading from standard input")
    }
}

private func recursiveFileEnumerator(path: String) -> AnySequence<String> {
    let fileManager = NSFileManager.defaultManager()

    let expandedPath = "\(Path(path).normalize())"

    var isDirectory: ObjCBool = false
    guard fileManager.fileExistsAtPath(expandedPath, isDirectory: &isDirectory) else {
        return AnySequence { AnyGenerator { nil } }
    }

    if isDirectory {
        let url = NSURL.fileURLWithPath(expandedPath, isDirectory: true)
        return AnySequence { fileManager.fileGeneratorAtURL(url) }
    } else {
        return AnySequence { [ path ].generate() }
    }
}

extension NSFileManager {
    func fileGeneratorAtURL(url: NSURL) -> AnyGenerator<String> {
        let enumerator = enumeratorAtURL(url,
            includingPropertiesForKeys: [NSURLIsDirectoryKey],
            options: [.SkipsHiddenFiles, .SkipsPackageDescendants],
            errorHandler: nil)

        return AnyGenerator {
            while let fileURL = enumerator.flatMap({$0.nextObject()}) as? NSURL {

                guard let resourceValues = try? fileURL.resourceValuesForKeys([ NSURLIsDirectoryKey ]),
                    let isDirectory = resourceValues[NSURLIsDirectoryKey] as? Bool else {
                        continue
                }

                if isDirectory {
                    continue
                } else {
                    return fileURL.path
                }
            }
            return nil
        }
    }
}
