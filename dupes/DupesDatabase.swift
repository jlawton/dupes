//
//  DupesDatabase.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

private let file = Table("file")
private let path = Expression<String>("path")
private let size = Expression<Int>("size")
private let hash = Expression<String?>("hash")
private let sharedSize = View("candidate")
private let dupe = View("dupe")

class DupesDatabase {

    private let connection: Connection

    init(location: Connection.Location) throws {
        try connection = Connection(location)
        try createDatabase()
    }

    func addFileRecord(fileRecord: FileRecord) throws {
        // Don't update if we'd just be deleting a hash
        if fileRecord.hash == nil {
            if let existing = selectFile(fileRecord.path) {
                if existing.size == fileRecord.size {
                    return
                }
            }
        }

        try connection.run(file.insert(or: .Replace, [
            path <- fileRecord.path,
            size <- fileRecord.size,
            hash <- fileRecord.hash
        ]))
    }

    func removeFileRecord(fileRecord: FileRecord) throws {
        try removeFileRecord(fileRecord.path)
    }

    func removeFileRecord(filePath: String) throws {
        try connection.run(file.filter(path == filePath).delete())
    }

    func duplicates() throws -> AnySequence<[FileRecord]> {
        let query = try connection.prepare(dupe
            .select([path, size, hash])
            .order([size.desc, hash]))
        return fileRecords(query).groupBy { "\($0.size):\($0.hash!)" }
    }

    func duplicates(fileRecord: FileRecord) throws -> [FileRecord] {
        if fileRecord.hash == nil {
            return []
        }

        let query = try connection.prepare(dupe
            .select([path, size, hash])
            .filter(size == fileRecord.size && hash == fileRecord.hash))
        let dupes = fileRecords(query).groupBy { "\($0.size):\($0.hash!)" }
        for files in dupes {
            return files
        }
        return []
    }

    func filesToHash() throws -> AnySequence<FileRecord> {
        let query = try connection.prepare(sharedSize
            .select([path, size])
            .order(size.desc)
        ).lazy.map({ row in
            FileRecord(path: row[path], size: row[size], hash: nil)
        })
        return AnySequence { query.generate() }
    }

    func nextFileToHash() -> FileRecord? {
        let query = sharedSize
            .select([path, size])
            .limit(1)
        guard let row = connection.pluck(query) else { return nil }
        return FileRecord(path: row[path], size: row[size], hash: nil)
    }

    private func selectFile(filePath: String) -> FileRecord? {
        let row = connection.pluck(file
            .select([path, size, hash])
            .filter(path == filePath))
        if let row = row {
            return FileRecord(path: row[path], size: row[size], hash: row[hash])
        }
        return nil
    }

    private func createDatabase() throws {
        // CREATE TABLE IF NOT EXISTS file (size INT NOT NULL, hash TEXT, path TEXT NOT NULL UNIQUE)
        try connection.run(file.create(ifNotExists: true) { t in
            t.column(size)
            t.column(hash)
            t.column(path, unique: true)
        })

        // CREATE INDEX IF NOT EXISTS size_hash_idx
        // ON file (size, hash)
        try connection.run(file.createIndex([size, hash], unique: false, ifNotExists: true))

        // CREATE VIEW IF NOT EXISTS candidate
        // AS SELECT path, size
        // FROM (file, (SELECT size AS duplicated_size FROM file GROUP BY size HAVING COUNT(*) > 1))
        // WHERE size == duplicated_size AND hash IS NULL
        try connection.run(
            "CREATE VIEW IF NOT EXISTS candidate" +
            " AS SELECT path, size" +
            " FROM (file, (SELECT size AS duplicated_size FROM file GROUP BY size HAVING COUNT(*) > 1))" +
            " WHERE size == duplicated_size AND hash IS NULL"
        )

        // CREATE VIEW dupe
        // AS SELECT path, size, hash
        // FROM (file, (SELECT size AS duplicated_size, hash AS duplicated_hash FROM file GROUP BY size, hash HAVING COUNT(*) > 1))
        // WHERE size == duplicated_size AND hash == duplicated_hash
        try connection.run(
            "CREATE VIEW IF NOT EXISTS dupe " +
            " AS SELECT path, size, hash" +
            " FROM (file, (SELECT size AS duplicated_size, hash AS duplicated_hash FROM file GROUP BY size, hash HAVING COUNT(*) > 1))" +
            " WHERE size == duplicated_size AND hash == duplicated_hash"
        )
    }

}

func fileRecords<S: SequenceType where S.Generator.Element == Row>(query: S) -> AnySequence<FileRecord> {
    return AnySequence {
        return query.lazy.map({ row in
            FileRecord(path: row[path], size: row[size], hash: row[hash])
        }).generate()
    }
}
