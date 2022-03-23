//
//  Readline+Sequence.swift
//  dupes
//
//  Created by James Lawton on 3/28/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

func readLines() -> AnySequence<String> {
    return AnySequence { AnyIterator { readLine(strippingNewline: true) } }
}

func readLines(_ path: String) -> AnySequence<String> {
    return AnySequence { LineReader(path: path) }
}

// After http://stackoverflow.com/questions/24581517/read-a-file-url-line-by-line-in-swift
private final class LineReader: IteratorProtocol {
    public let path: String
    private let file: UnsafeMutablePointer<FILE>?

    init(path: String) {
        self.path = path
        file = fopen(path, "r")
    }

    deinit {
        if file != nil {
            fclose(file)
        }
    }

    public func next() -> String? {
        if file == nil { return nil }
        
        var line: UnsafeMutablePointer<CChar>? = nil
        var linecap: Int = 0
        defer { free(line) }

        return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
    }
}
