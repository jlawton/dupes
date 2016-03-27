//
//  DupesDatabase+Operations.swift
//  dupes
//
//  Created by James Lawton on 3/27/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

extension DupesDatabase {

    func hashAllCandidates() throws {
        for file in try filesToHash() {
            printErr("Hashing \(file.path)")
            if let hashed = file.withHash() {
                try addFileRecord(hashed)
            } else {
                printErr("Unable to hash file: \(file.path)")
            }
        }
    }

    func duplicateStats() throws {
        // numerofduplicatesingroup: (wastedspace, numberofgroups)
        var duplicateSizes: [Int: (Int, Int)] = [:]
        for dupes in try duplicates() {
            let acc = duplicateSizes[dupes.count] ?? (0, 0)
            duplicateSizes[dupes.count] = (acc.0 + dupes[0].size * (dupes.count - 1), acc.1 + 1)
        }

        let totalWastedSpace = duplicateSizes.reduce(0) { (acc, rec) in
            switch rec {
            case (_, (let wasted, _)):
                return acc + wasted
            }
        }

        printErr("Total Wasted Space: \(human(totalWastedSpace))")
    }

}
