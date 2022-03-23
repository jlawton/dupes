//
//  Result+Try.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import Result

public extension Result {

    /// Performs a side effect on value, keeping the value or propogating an error from the side effect.
    func tryPassthrough(_ sideEffect: (Value) throws -> Void) -> Result<Value, Error> where Failure: ErrorConvertible {
        return tryMap { value in
            try sideEffect(value)
            return value
        }
    }
}
