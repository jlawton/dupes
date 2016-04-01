//
//  main.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

let defaultDatabasePath = "~/.dupes.db"

func printErr(string: String) {
    fputs("\(string)\n", __stderrp)
}

func main() {
    let commands = CommandRegistry<DupesError>()
    commands.register(VersionCommand())
    commands.register(AddCommand())
    commands.register(HashCommand())
    commands.register(InteractiveCommand())
    commands.register(ListCommand())
    commands.register(ReindexCommand())
    commands.register(RemoveCommand())
    commands.register(SummaryCommand())
    commands.register(HelpCommand(registry: commands))

    commands.main(defaultVerb: "help") { error in
        print("\(error)")
    }
}

main()
