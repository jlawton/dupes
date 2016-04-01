//
//  InteractiveCommand.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct InteractiveCommand: CommandType {
    typealias Options = InteractiveCommandOptions

    let verb = "interactive"
    let function = "List all duplicates interactively"

    func run(options: InteractiveCommandOptions) -> Result<(), DupesError> {
        return DupesDatabase.open(options.dbPath).tryMap({ db in
            let tmp = NSFileHandle.temporaryFile("dupelist", suffix: ".dupes")
            tmp.0.writeData(dupes_interactive_txt.dataUsingEncoding(NSUTF8StringEncoding)!)
            var first = true
            for group in try db.listDuplicates("  ") {
                if first { first = false }
                else { tmp.0.writeData("\n\n".dataUsingEncoding(NSUTF8StringEncoding)!) }
                tmp.0.writeData(group.dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            tmp.0.closeFile()
            return tmp.1
        }).flatMap({ (listURL: NSURL) -> Result<(), DupesError> in
            let rc = writeVimrc()
            defer {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(rc)
                    try NSFileManager.defaultManager().removeItemAtURL(listURL)
                } catch {}
            }
            if executeVim(listURL, configFile: rc) != nil {
                return Result(value: ())
            }
            return Result(error: .Unknown("Command not found: vim"))
        })
    }
}

struct InteractiveCommandOptions: OptionsType {
    let dbPath: String

    static func create(dbPath: String) -> InteractiveCommandOptions {
        return InteractiveCommandOptions(dbPath: dbPath)
    }

    static func evaluate(m: CommandMode) -> Result<InteractiveCommandOptions, CommandantError<DupesError>> {
        return create
            <*> m <| databaseOption
    }
}

func writeVimrc() -> NSURL {
    let tmp = NSFileHandle.temporaryFile("dupes", suffix: ".vimrc")
    tmp.0.writeData(dupes_vimrc.dataUsingEncoding(NSUTF8StringEncoding)!)
    tmp.0.closeFile()
    return tmp.1
}

private func executeVim(file: NSURL, configFile: NSURL?) -> Int32? {
    var arguments = [String]()
    if let configPath = configFile?.path {
        arguments.appendContentsOf([ "-u", configPath ])
    }
    arguments.append(file.path!)

    return executeCommandIfExists("mvim", arguments: [ "-f" ] + arguments)
}

private func executeCommandIfExists(commandName: String, arguments: [String]) -> Int32? {
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

