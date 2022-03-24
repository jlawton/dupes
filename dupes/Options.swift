//
//  Options.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant
import PathKit

let defaultDatabasePath = "~/.dupes.db"

struct DatabaseOptions: OptionsProtocol {
    let path: String

    static func create(path: String) -> DatabaseOptions {
        return DatabaseOptions(path: path)
    }

    static func evaluate(_ m: CommandMode) -> Result<DatabaseOptions, CommandantError<DupesError>> {
        let databasePathFromEnvironment = ProcessInfo.processInfo.environment["DUPES_DB_PATH"]
        let databasePath = databasePathFromEnvironment ?? defaultDatabasePath
        let defaultPathUsage = databasePathFromEnvironment == nil
            ? "default: \(databasePath)"
            : "DUPES_DB_PATH: \(databasePath)"
        return create
            <*> m <| Option(key: "db", defaultValue: databasePath, usage: "Use the specified database file (\(defaultPathUsage))")
    }
}

struct ListOptions: OptionsProtocol {
    let bare: Bool
    let fileSeparator: String

    var groupSeparator: String {
        return "\(fileSeparator)\(fileSeparator)"
    }

    static func create(bare: Bool) -> (Bool) -> ListOptions {
        return { nulSeparator in
            let fileSeparator = nulSeparator ? "\0" : "\n"
            return ListOptions(
                bare: (bare || nulSeparator),
                fileSeparator: fileSeparator)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<ListOptions, CommandantError<DupesError>> {
        return create
            <*> m <| Switch(flag: nil, key: "bare", usage: "Display grouped file paths without summary data")
            <*> m <| Switch(flag: nil, key: "print0", usage: "Separate files with NUL characters, rather than by line. Implies --bare")
    }
}

struct DeleteOptions: OptionsProtocol {
    let trash: Bool

    func deleteFile(_ path: String) throws {
        let url = URL(fileURLWithPath: path)
        if trash {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } else {
            try FileManager.default.removeItem(at: url)
        }
    }

    static func create(trash: Bool) -> DeleteOptions {
        return DeleteOptions(trash: trash)
    }

    static func evaluate(_ m: CommandMode) -> Result<DeleteOptions, CommandantError<DupesError>> {
        return create
            <*> m <| Switch(flag: nil, key: "trash", usage: "Trash files rather than deleting them")
    }
}

struct HashOptions: OptionsProtocol {
    enum HashFiles: String, ArgumentProtocol {
        case candidates
        case all

        // ArgumentProtocol
        static let name = "candidates|all"
    }
    let hashFiles: HashFiles

    static func create(hashFiles: HashFiles) -> HashOptions {
        return HashOptions(hashFiles: hashFiles)
    }

    static func evaluate(_ m: CommandMode) -> Result<HashOptions, CommandantError<DupesError>> {
        return create
        <*> m <| Option(key: "hash-files", defaultValue: HashFiles.candidates, usage: "Determine which files to hash (default: candidates)")
    }
}

struct FileArguments: OptionsProtocol {
    private let recursive: Bool
    private let givenFilePaths: [String]?

    var filesPaths: AnySequence<String> {
        let files = (givenFilePaths != nil)
            ? AnySequence(self.givenFilePaths!)
            : readLines()

        if recursive {
            let sequence = files.lazy.flatMap(recursiveFileEnumerator)
            return AnySequence(sequence)
        }
        return files
    }

    static func create(recursive: Bool) -> ([String]) -> FileArguments {
        return { paths in
            let filePaths: [String]? = (!paths.isEmpty) ? paths : nil
            return FileArguments(recursive: recursive, givenFilePaths: filePaths)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<FileArguments, CommandantError<DupesError>> {
        return create
            <*> m <| Switch(flag: "r", key: "recursive", usage: "Recurse files in given directories")
            <*> m <| Argument(defaultValue: [], usage: "Files to index, rather than reading from standard input")
    }
}

private func recursiveFileEnumerator(path: String) -> AnySequence<String> {
    let fileManager = FileManager.default

    let expandedPath = "\(Path(path).normalize())"

    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: expandedPath, isDirectory: &isDirectory) else {
        return AnySequence { AnyIterator { nil } }
    }

    if isDirectory.boolValue {
        let url = URL(fileURLWithPath: expandedPath, isDirectory: true)
        return AnySequence { fileManager.fileIterator(at: url) }
    } else {
        return AnySequence([path])
    }
}

extension FileManager {
    func fileIterator(at url: URL) -> AnyIterator<String> {
        let enumerator = enumerator(at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil)

        return AnyIterator {
            while let fileURL = enumerator.flatMap({$0.nextObject()}) as? NSURL {

                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                      let isDirectory = resourceValues[.isDirectoryKey] as? Bool else {
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
