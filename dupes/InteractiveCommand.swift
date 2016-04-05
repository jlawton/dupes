//
//  InteractiveCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct InteractiveCommand: CommandType {
    let verb = "interactive"
    let function = "List all duplicates interactively"

    func run(options: InteractiveCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.db.path).flatMap { InteractiveCommand.run($0, deleteOptions: options.delete, reopenTTY: false) }
    }

    static func run(db: DupesDatabase, deleteOptions: DeleteOptions, reopenTTY: Bool) -> Result<(), DupesError> {
        return Result(value: db)
            .tryMap({ db in
                let tmp = NSFileHandle.temporaryFile("dupelist", suffix: ".dupes")
                try writeInteractiveDuplicatesList(db, to: tmp.0)
                tmp.0.closeFile()
                return (db, tmp.1)
            })
            .flatMap({ (db: DupesDatabase, listURL: NSURL) -> Result<(DupesDatabase, NSURL), DupesError> in
                if editInteractiveDuplicatesList(listURL, reopenTTY: reopenTTY) {
                    return Result(value: (db, listURL))
                }
                do { try NSFileManager.defaultManager().removeItemAtURL(listURL) } catch {}
                return Result(error: .Unknown("Command not found: mvim"))
            })
            .flatMap({ (db: DupesDatabase, listURL: NSURL) -> Result<(), DupesError> in
                defer {
                    do {
                        try NSFileManager.defaultManager().removeItemAtURL(listURL)
                    } catch {}
                }

                let filesToDelete = parseMarkedList(listURL).flatMap({ (marked: Marked<String>) -> Marked<FileRecord>? in
                    marked.flatMap { db.findFileRecord($0) }
                })

                let size = filesToDelete.map({ (marked: Marked<FileRecord>) -> Int in
                    switch marked {
                    case .ForDeletion(let record):
                        return record.size
                    }
                }).reduce(0, combine: +)

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
                        try db.removeFileRecord(f.unwrap)
                    } catch {}
                }

                // We might have had a significant number of deletions
                do { try db.vacuum() } catch {}

                return Result(value: ())
            })
    }
}

struct InteractiveCommandOptions: OptionsType {
    let db: DatabaseOptions
    let delete: DeleteOptions

    static func create(db: DatabaseOptions) -> DeleteOptions -> InteractiveCommandOptions {
        return { delete in
            InteractiveCommandOptions(db: db, delete: delete)
        }
    }

    static func evaluate(m: CommandMode) -> Result<InteractiveCommandOptions, CommandantError<DupesError>> {
        return create
            <*> DatabaseOptions.evaluate(m)
            <*> DeleteOptions.evaluate(m)
    }
}

private func writeVimrc() -> NSURL {
    let tmp = NSFileHandle.temporaryFile("dupes", suffix: ".vimrc")
    tmp.0.writeData(dupes_vimrc.dataUsingEncoding(NSUTF8StringEncoding)!)
    tmp.0.closeFile()
    return tmp.1
}

private func writeInteractiveDuplicatesList(db: DupesDatabase, to fileHandle: NSFileHandle) throws {
    fileHandle.writeData(dupes_interactive_txt.dataUsingEncoding(NSUTF8StringEncoding)!)
    var first = true
    for group in try db.listDuplicates("  ") {
        if first { first = false }
        else { fileHandle.writeData("\n\n".dataUsingEncoding(NSUTF8StringEncoding)!) }
        fileHandle.writeData(group.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
}

private func editInteractiveDuplicatesList(listURL: NSURL, reopenTTY: Bool) -> Bool {
    let rc = writeVimrc()
    defer {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(rc)
        } catch {}
    }
    return (executeVim(listURL, configFile: rc, reopenTTY: reopenTTY) ?? executeMVim(listURL, configFile: rc)) != nil
}

private func executeVim(file: NSURL, configFile: NSURL?, reopenTTY: Bool) -> Int32? {
    var arguments = [String]()
    if let configPath = configFile?.path {
        arguments.appendContentsOf([ "-u", configPath ])
    }
    arguments.append(file.path!)

    let task = ForkExecTask.launchVimWithArguments(arguments, reopenTTY: reopenTTY)

    if let task = task {
        task.waitUntilExit()
        return task.terminationStatus
    }
    return nil
}

private func executeMVim(file: NSURL, configFile: NSURL?) -> Int32? {
    var arguments = [String]()
    if let configPath = configFile?.path {
        arguments.appendContentsOf([ "-u", configPath ])
    }
    arguments.append(file.path!)

    return executeCommandIfExists("mvim", arguments: [ "-f" ] + arguments)
}

func executeCommandIfExists(commandName: String, arguments: [String]) -> Int32? {
    func launchTask(path: String, arguments: [String]) -> Int32 {
        let task = NSTask()
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

    @warn_unused_result
    func map<U>(@noescape transform: T throws -> U) rethrows -> Marked<U> {
        switch self {
        case .ForDeletion(let t):
            return .ForDeletion(try transform(t))
        }
    }

    @warn_unused_result
    func flatMap<U>(@noescape transform: T throws -> U?) rethrows -> Marked<U>? {
        switch self {
        case .ForDeletion(let t):
            return try transform(t).map { .ForDeletion($0) }
        }
    }
}

private func parseMarkedList(url: NSURL) -> AnySequence<Marked<String>> {
    return AnySequence {
        readLines(url.path!)
            .lazy
            .filter({ $0.hasPrefix("x /") })
            .map({ ($0 as NSString).substringFromIndex(2) })
            .map({ .ForDeletion($0) })
            .generate()
    }
}
