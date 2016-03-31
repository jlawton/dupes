//
//  TemporaryFile.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

extension NSFileHandle {
    static func temporaryFile(name: String, suffix maybeSuffix: String? = nil) -> (NSFileHandle, NSURL) {
        let basename = Path(name).lastComponent
        let suffix = maybeSuffix ?? ""
        assert(Path(suffix).components.count == 1)
        let suffixLength = Int32(suffix.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))

        // The template string:
        let template = NSURL(fileURLWithPath: NSTemporaryDirectory())
            .URLByAppendingPathComponent("\(basename).XXXXXX\(suffix)")

        // Fill buffer with a C string representing the local file system path.
        var buffer = [Int8](count: Int(PATH_MAX), repeatedValue: 0)
        assert(template.getFileSystemRepresentation(&buffer, maxLength: buffer.count))

        // Create unique file name (and open file):
        let fd = mkstemps(&buffer, suffixLength)
        assert(fd != -1, String(strerror(errno)))

        // Create URL from file system string:
        let url = NSURL(fileURLWithFileSystemRepresentation: buffer, isDirectory: false, relativeToURL: nil)
        let fileHandle = NSFileHandle(fileDescriptor: fd, closeOnDealloc: true)
        return (fileHandle, url)
    }
}

