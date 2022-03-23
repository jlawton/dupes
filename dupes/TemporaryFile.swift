//
//  TemporaryFile.swift
//  dupes
//
//  Created by James Lawton on 3/31/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import PathKit

extension FileHandle {
    static func temporaryFile(name: String, suffix maybeSuffix: String? = nil) -> (FileHandle, URL) {
        let basename = Path(name).lastComponent
        let suffix = maybeSuffix ?? ""
        assert(Path(suffix).components.count == 1)
        let suffixLength = Int32(suffix.lengthOfBytes(using: .utf8))

        // The template string:
        let template = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(basename).XXXXXX\(suffix)")

        return template.withUnsafeFileSystemRepresentation({
            (templateRepresentation: UnsafePointer<Int8>?) -> (FileHandle, URL) in
            assert(templateRepresentation != nil, "Failed to get file system representation")

            // Copy to mutable memory
            var buffer = [Int8](repeating: 0, count: Int(PATH_MAX))
            let fd = buffer.withUnsafeMutableBytes { bufferBytes -> Int32 in
                let n = strlcpy(bufferBytes.baseAddress, templateRepresentation, bufferBytes.count)
                assert(n < bufferBytes.count, "Temporary file path too long")

                // Create unique file name (and open file):
                let fd = mkstemps(bufferBytes.baseAddress, suffixLength)
                assert(fd != -1, String(cString: strerror(errno)))
                return fd
            }

            // Create URL from file system string:
            let url = URL(fileURLWithFileSystemRepresentation: buffer, isDirectory: false, relativeTo: nil)
            let fileHandle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
            return (fileHandle, url)
        })
    }
}

