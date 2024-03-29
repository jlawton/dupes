//
//  Sequence+GroupBy.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

extension Sequence {
    func groupBy<T: Equatable>(_ group: @escaping (Element) -> T) -> AnySequence<[Element]> {
        return AnySequence {
            return GroupedIterator(inner: self.makeIterator(), group: group)
        }
    }
}

private struct GroupedIterator<G: IteratorProtocol, T: Equatable>: IteratorProtocol {
    var inner: G
    let group: (G.Element) -> T

    private var started: Bool = false
    private var nextValue: G.Element? = nil
    private var groupID: T! = nil

    init(inner: G, group: @escaping (G.Element) -> T) {
        self.inner = inner
        self.group = group
    }

    mutating func next() -> [G.Element]? {
        // Initial setup
        if !started {
            nextValue = inner.next()
            started = true
            guard let v = nextValue else { return nil }
            groupID = group(v)
        }

        // We ended last time round
        if nextValue == nil {
            return nil
        }

        var acc = [nextValue!]
        while true {
            nextValue = inner.next()
            // End if we have no next value
            guard let v = nextValue else {
                groupID = nil
                return acc
            }
            // Check if we're in the same group
            let nextGroupID = group(v)
            if nextGroupID == groupID {
                // Keep adding to the group
                acc.append(v)
            } else {
                // Set up for the next group and return the current group
                groupID = nextGroupID
                return acc
            }
        }
    }
}
