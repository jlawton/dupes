//
//  DupesError.swift
//  dupes
//
//  Created by James Lawton on 3/29/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Result

enum DupesError: Error {
    case Database(String, db: String)
    case Unknown(String)
}

extension DupesError: ErrorConvertible {
    static func error(from error: Error) -> DupesError {
        return .Unknown("\(error)")
    }
}

extension DupesError: CustomStringConvertible {
    var description: String {
        switch self {
        case .Database(let msg, db: let path):
            return "Database error: \(msg) (\(path))"
        case .Unknown(let msg):
            return "Error: \(msg)"
        }
    }
}
