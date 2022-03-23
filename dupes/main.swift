//
//  main.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Commandant

func printErr(_ string: String) {
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
    commands.register(RemountCommand())
    commands.register(RemoveCommand())
    commands.register(RunCommand())
    commands.register(SummaryCommand())
    commands.register(ExecCommand())
    commands.register(HelpCommand(registry: commands))

    commands.main(defaultVerb: "help") { error in
        print("\(error)")
    }
}

main()
