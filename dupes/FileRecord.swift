//
//  FileRecord.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct FileRecord {
    let path: String
    var size: Int
    var hash: String?
}

extension FileRecord {
    func withHash() -> FileRecord? {
        var file = self
        file.addHash()
        guard file.hash != nil else { return nil }
        return file
    }

    private mutating func addHash() {
        if hash == nil {
            if let h = sha1File(self.path) {
                hash = h.hexEncodedString()
            }
        }
    }
}

extension FileRecord {
    static func fromFile(atPath path: String) -> FileRecord? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            guard let fileSize = attr[.size] as? NSNumber else { return nil }

            let size: Int = fileSize.intValue
            return FileRecord(path: path, size: size, hash: nil)
        } catch {
            return nil
        }
    }
}

func sha1File(_ path: String) -> Data? {
    guard let file = FileHandle(forReadingAtPath: path) else { return nil }
    defer { file.closeFile() }

    let ctx = UnsafeMutablePointer<CC_SHA1_CTX>.allocate(capacity: 1)
    defer { ctx.deallocate() }

    CC_SHA1_Init(ctx)

    var done = false
    while !done {
        autoreleasepool {
            let data = file.readData(ofLength: 8 * 1024)
            if data.isEmpty {
                done = true
            } else {
                _ = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
                    CC_SHA1_Update(ctx, buffer.baseAddress, CC_LONG(buffer.count))
                }
            }
        }
    }

    var outData = Data(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    _ = outData.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
        CC_SHA1_Final(buffer.bindMemory(to: UInt8.self).baseAddress, ctx)
    }
    return outData
}
