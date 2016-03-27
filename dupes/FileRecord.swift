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
            if let h = md5File(self.path) {
                hash = h.hexString
            }
        }
    }
}

func md5File(path: String) -> NSData? {
    guard let file = NSFileHandle(forReadingAtPath: path) else { return nil }

    guard let ctxData = NSMutableData(length: sizeof(CC_MD5_CTX)) else {
        file.closeFile()
        return nil
    }
    let ctx = UnsafeMutablePointer<CC_MD5_CTX>(ctxData.mutableBytes)

    CC_MD5_Init(ctx)

    var done = false
    while !done {
        autoreleasepool {
            let data = file.readDataOfLength(8 * 1024)
            if data.length == 0 {
                done = true
            } else {
                CC_MD5_Update(ctx, data.bytes, CC_LONG(data.length))
            }
        }
    }

    file.closeFile()

    guard let outData = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH)) else { return nil }
    CC_MD5_Final(UnsafeMutablePointer<UInt8>(outData.mutableBytes), ctx)

    return outData
}
