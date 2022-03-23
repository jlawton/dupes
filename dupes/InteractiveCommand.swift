//
//  InteractiveCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

struct InteractiveCommand: CommandProtocol {
    let verb = "interactive"
    let function = "List all duplicates interactively"

    func run(_ options: InteractiveCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).flatMap { InteractiveCommand.run(db: $0, deleteOptions: options.delete, reopenTTY: false) }
    }

    static func run(db: DupesDatabase, deleteOptions: DeleteOptions, reopenTTY: Bool) -> Result<(), DupesError> {
        return Result(value: db)
            .tryMap({ db in
                let tmp = FileHandle.temporaryFile(name: "dupelist", suffix: ".dupes")
                try writeInteractiveDuplicatesList(db: db, to: tmp.0)
                tmp.0.closeFile()
                return (db, tmp.1)
            })
            .flatMap({ (db: DupesDatabase, listURL: URL) -> Result<(DupesDatabase, URL), DupesError> in
                if editInteractiveDuplicatesList(listURL, reopenTTY: reopenTTY) {
                    return .success((db, listURL))
                }
                do { try FileManager.default.removeItem(at: listURL) } catch {}
                return Result(error: .Unknown("Command not found: mvim"))
            })
            .flatMap({ (db: DupesDatabase, listURL: URL) -> Result<(), DupesError> in
                defer {
                    do {
                        try FileManager.default.removeItem(at: listURL)
                    } catch {}
                }

                let filesToDelete = parseMarkedList(listURL).compactMap({ (marked: Marked<String>) -> Marked<FileRecord>? in
                    marked.flatMap { db.findFileRecord(filePath: $0) }
                })

                let size = filesToDelete.map({ (marked: Marked<FileRecord>) -> Int in
                    switch marked {
                    case .ForDeletion(let record):
                        return record.size
                    }
                }).reduce(0, +)

                print("Marked \(filesToDelete.count) files with total size \(human(size))\n")

                if filesToDelete.count == 0 {
                    return Result(value: ())
                }

                if isatty(STDIN_FILENO) != 1 {
                    reopenStandardInputTTY()
                }

                var ok = false
                while !ok {
                    guard let ans = prompt("Are you sure you want to delete these files? [yes/no/list]", defaultChoice: ":") else {
                        return Result(value: ())
                    }
                    switch ans {
                    case "n", "N": return Result(value: ())
                    case "l", "L":
                        for f in filesToDelete {
                            print(f.unwrap.path)
                        }
                    case "y", "Y": ok = true
                    default: break
                    }
                }

                for f in filesToDelete {
                    do {
                        try deleteOptions.deleteFile(f.unwrap.path)
                    } catch {
                        printErr("Failed to remove \(f.unwrap.path): \((error as NSError).localizedDescription)")
                        continue
                    }
                    do {
                        _ = try db.removeFileRecord(f.unwrap)
                    } catch {}
                }

                // We might have had a significant number of deletions
                do { try db.vacuum() } catch {}

                return Result(value: ())
            })
    }
}

struct InteractiveCommandOptions: OptionsProtocol {
    let db: DatabaseOptions
    let delete: DeleteOptions

    static func create(db: DatabaseOptions) -> (DeleteOptions) -> InteractiveCommandOptions {
        return { delete in
            InteractiveCommandOptions(db: db, delete: delete)
        }
    }

    static func evaluate(_ m: CommandMode) -> Result<InteractiveCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> DeleteOptions.evaluate(m)
    }
}

private func writeVimrc() -> URL {
    let tmp = FileHandle.temporaryFile(name: "dupes", suffix: ".vimrc")
    tmp.0.write(dupes_vimrc.data(using: .utf8)!)
    tmp.0.closeFile()
    return tmp.1
}

private func writeInteractiveDuplicatesList(db: DupesDatabase, to fileHandle: FileHandle) throws {
    fileHandle.write(dupes_interactive_txt.data(using: .utf8)!)
    var first = true
    for group in try db.listDuplicates(indent: "  ") {
        if first { first = false }
        else { fileHandle.write("\n\n".data(using: .utf8)!) }
        fileHandle.write(group.data(using: .utf8)!)
    }
}

private func editInteractiveDuplicatesList(_ listURL: URL, reopenTTY: Bool) -> Bool {
    let rc = writeVimrc()
    defer {
        do {
            try FileManager.default.removeItem(at: rc)
        } catch {}
    }
    return (executeVim(listURL, configFile: rc, reopenTTY: reopenTTY) ?? executeMVim(listURL, configFile: rc)) != nil
}

private func executeVim(_ file: URL, configFile: URL?, reopenTTY: Bool) -> Int32? {
    var arguments = [String]()
    if let configPath = configFile?.path {
        arguments.append(contentsOf: [ "-u", configPath ])
    }
    arguments.append(file.path)

    let task = ForkExecTask.launchVim(withArguments: arguments, reopenTTY: reopenTTY)

    if let task = task {
        task.waitUntilExit()
        return task.terminationStatus
    }
    return nil
}

private func executeMVim(_ file: URL, configFile: URL?) -> Int32? {
    var arguments = [String]()
    if let configPath = configFile?.path {
        arguments.append(contentsOf: [ "-u", configPath ])
    }
    arguments.append(file.path)

    return executeCommandIfExists("mvim", arguments: [ "-f" ] + arguments)
}

func executeCommandIfExists(_ commandName: String, arguments: [String]) -> Int32? {
    func launchTask(_ path: String, arguments: [String]) -> Int32 {
        let task = Process()
        task.launchPath = path
        task.arguments = arguments

        task.launch()
        task.waitUntilExit()

        return task.terminationStatus
    }

    guard launchTask("/usr/bin/which", arguments: [ "-s", commandName ]) == 0 else {
        return nil
    }

    return launchTask("/usr/bin/env", arguments: [ commandName ] + arguments)
}

enum Marked<T> {
    case ForDeletion(T)

    var unwrap: T {
        switch self {
        case .ForDeletion(let t):
            return t
        }
    }

    func map<U>(transform: (T) throws -> U) rethrows -> Marked<U> {
        switch self {
        case .ForDeletion(let t):
            return .ForDeletion(try transform(t))
        }
    }

    func flatMap<U>(transform: (T) throws -> U?) rethrows -> Marked<U>? {
        switch self {
        case .ForDeletion(let t):
            return try transform(t).map { .ForDeletion($0) }
        }
    }
}

private func parseMarkedList(_ url: URL) -> AnySequence<Marked<String>> {
    return AnySequence(
        readLines(url.path)
            .lazy
            .filter({ $0.hasPrefix("x /") })
            .map({ String($0.dropFirst(2)) })
            .map({ .ForDeletion($0) })
    )
}
