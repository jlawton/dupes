//
//  Result+Try.swift
//  dupes
//
//  Created by James Lawton on 4/2/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

public extension ResultType where Error: ErrorTypeConvertible {

    /// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
    public func tryPassthrough(@noescape sideEffect: Value throws -> Void) -> Result<Value, Error> {
        return tryMap { value in
            try sideEffect(value)
            return value
        }
    }
}
