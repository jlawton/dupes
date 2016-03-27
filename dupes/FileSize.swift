//
//  FileSize.swift
//  dupes
//
//  Created by James Lawton on 3/27/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

func human(fileSize: Int) -> String {
    let sizeClasses = [
        (1024 * 1024 * 1024 * 1024 * 1024, "PB"),
        (1024 * 1024 * 1024 * 1024, "TB"),
        (1024 * 1024 * 1024, "GB"),
        (1024 * 1024, "MB"),
        (1024, "KB"),
    ]
    for (size, unit) in sizeClasses {
        if fileSize >= size {
            let sizeInUnit = Double(fileSize) / Double(size)
            return "\(sizeInUnit)\(unit)"
        }
    }
    return "\(fileSize)B"
}
