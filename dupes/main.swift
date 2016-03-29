//
//  main.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

func printErr(string: String) {
    fputs("\(string)\n", __stderrp)
}

func addFilesFromStandardInput(db: DupesDatabase) throws {
     while let rawPath = readLine(stripNewline: true) {
        let path = Path(rawPath).absolute()
        try addFile(path, db: db)
    }
}

func addFile(path: Path, db: DupesDatabase) throws {
    guard path.isFile else {
        printErr("Not a file: \(path)")
        return
    }

    if let fileRecord = FileRecord.fromFileAtPath("\(path)") {
        printErr("Adding: \(path)")
        try db.addFileRecord(fileRecord)
    } else {
        printErr("Failed to get file size: \(path)")
    }
}

func removeFilesFromStandardInput(db: DupesDatabase) throws {
    while let rawPath = readLine(stripNewline: true) {
        let path = Path(rawPath).absolute()
        try db.removeFileRecord("\(path)")
    }
}

func main() {

    let args = Process.arguments
    if args.count != 2 {
        usage()
        return
    }

    var _db: DupesDatabase?
    let dbPath = "\(Path("~/.dupes.db").absolute())"
    do {
        _db = try DupesDatabase(location: .URI(dbPath))
    } catch let e {
        printErr("Failed to open database: \(e); dbpath = \(dbPath)")
    }
    guard let db = _db else { return }

    switch args[1] {
    case "add", "index":
        do {
            try addFilesFromStandardInput(db)
        } catch let e {
            printErr("Failed to add file: \(e)")
        }
    case "hash":
        do {
            try db.hashAllCandidates()
        } catch let e {
            printErr("Failed to store hash: \(e)")
        }
    case "remove", "unindex":
        do {
            try removeFilesFromStandardInput(db)
        } catch let e {
            printErr("Failed to add file: \(e)")
        }
    case "reindex":
        do {
            try db.reIndex(duplicatesOnly: true)
        } catch let e {
            printErr("Failed to reindex: \(e)")
        }
    case "reindexall":
        do {
            try db.reIndex()
        } catch let e {
            printErr("Failed to reindex: \(e)")
        }
    case "list":
        do {
            for files in try db.groupedDuplicates() {
                print("[Files of size \(human(files[0].size))]")
                for f in files {
                    print("\(f.path)")
                }
                print("")
            }
        } catch let e {
            printErr("Failed to get duplicates: \(e)")
        }
    case "stats":
        do {
            try db.duplicateStats()
        } catch let e {
            printErr("Failed to get stats: \(e)")
        }
    default:
        usage()
    }

}

func usage() {
    print("Usage: dupes <command>")
    print("Commands:")
    print("  add         Index files passed in, on per line, on standard input.")
    print("  hash        Hash all indexed files that might be duplicates.")
    print("  remove      Unindex files passed in, on per line, on standard input.")
    print("  reindex     Unindex all deleted duplicates, and unhash changed duplicates.")
    print("  reindexall  Unindex all deleted duplicates, and unhash changed duplicates.")
    print("  list        List all duplicates.")
    print("  stats       Show summary of duplicates.")
}

main()
