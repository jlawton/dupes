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

    let attr = try NSFileManager.defaultManager().attributesOfItemAtPath("\(path)")
    if let fileSize = attr[NSFileSize]  {
        let size: Int = (fileSize as! NSNumber).integerValue
        let fileRecord = FileRecord(path: "\(path)", size: size, hash: nil)
        printErr("Adding: \(path)")
        try db.addFileRecord(fileRecord)
    } else {
        printErr("Failed to get file size: \(path)")
    }
}

func main() {
    var _db: DupesDatabase?
    let dbPath = "\(Path("~/.dupes.db").normalize())"
    do {
        _db = try DupesDatabase(location: .URI(dbPath))
    } catch let e {
        printErr("Failed to open database: \(e); dbpath = \(dbPath)")
    }

    guard let db = _db else { return }

    do {
        try addFilesFromStandardInput(db)
    } catch let e {
        printErr("Failed to do something: \(e)")
    }

    do {
        try db.hashAllCandidates()
    } catch let e {
        printErr("Failed to store hash: \(e)")
    }

    do {
        try db.duplicateStats()
    } catch let e {
        printErr("Failed to get stats: \(e)")
    }

    do {
        for files in try db.duplicates() {
            print("[Files of size \(human(files[0].size))]")
            for f in files {
                print("\(f.path)")
            }
            print("")
        }
    } catch let e {
        printErr("Failed to get duplicates: \(e)")
    }
}

main()
