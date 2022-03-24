//
//  DupesDatabase.swift
//  dupes
//
//  Created by James Lawton on 3/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import SQLite
import PathKit

private let file = Table("file", database: "main")
private let sharedSize = View("candidate", database: "main")
private let dupe = View("dupe", database: "main")
private let id = Expression<Int64>("id")
private let path = Expression<String>("path")
private let size = Expression<Int>("size")
private let hash = Expression<String?>("hash")

private let added = Table("added", database: "temp")
private let addedSharedSize = View("added_candidate", database: "temp")
private let addedDupe = View("added_dupe", database: "temp")
private let file_id = Expression<Int64>("file_id")

final class DupesDatabase {

    private let connection: Connection
    private let trackAdditions: Bool

    init(location: Connection.Location, trackAdditions: Bool = false) throws {
        self.trackAdditions = trackAdditions

        try connection = Connection(location)
        try createDatabase()

        if trackAdditions {
            try createTemporaries()
        }
    }

    func addFileRecord(_ fileRecord: FileRecord, force: Bool = false) throws {
        var fileRecordToInsert = fileRecord

        // Don't update if we'd just be deleting a hash
        if !force && (fileRecord.hash == nil) {
            if let existing = selectFile(fileRecord.path) {
                if existing.size == fileRecord.size {
                    guard trackAdditions else { return }
                    fileRecordToInsert = existing
                }
            }
        }

        try connection.run(file.insert(or: .replace, [
            path <- fileRecordToInsert.path,
            size <- fileRecordToInsert.size,
            hash <- fileRecordToInsert.hash
        ]))
    }

    func removeFileRecord(_ fileRecord: FileRecord) throws -> Bool {
        return try removeFileRecord(filePath: fileRecord.path)
    }

    func removeFileRecord(filePath: String) throws -> Bool {
        let rowCount = try connection.run(file.filter(path == filePath).delete())
        return rowCount == 1
    }

    func findFileRecord(filePath: String) -> FileRecord? {
        return selectFile(filePath)
    }

    func allFiles() throws -> AnySequence<FileRecord> {
        let query = try connection.prepare(file
            .select([path, size, hash]))
        return fileRecords(query)
    }

    func unhashed() throws -> AnySequence<FileRecord> {
        let query = try connection.prepare(file
            .select(distinct: [path, size])
            .where(hash == nil))
        return AnySequence(
            query.lazy.map({ row in
                FileRecord(path: row[path], size: row[size], hash: nil)
            })
        )
    }

    func duplicates(addedOnly: Bool = false) throws -> AnySequence<FileRecord> {
        if addedOnly {
            assert(self.trackAdditions)
        }
        let table = addedOnly ? addedDupe : dupe

        let query = try connection.prepare(table
            .select([path, size, hash])
            .order([size.desc, hash]))
        return fileRecords(query)
    }

    func groupedDuplicates(addedOnly: Bool = false) throws -> AnySequence<[FileRecord]> {
        return try duplicates(addedOnly: addedOnly).groupBy({ "\($0.size):\($0.hash!)" })
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

    func filesToHash(addedOnly: Bool = false) throws -> AnySequence<FileRecord> {
        if addedOnly {
            assert(self.trackAdditions)
        }
        let table = addedOnly ? addedSharedSize : sharedSize

        let query = try connection.prepare(table
            .select([path, size])
            .order(size.desc)
        ).lazy.map({ row in
            FileRecord(path: row[path], size: row[size], hash: nil)
        })
        return AnySequence(query)
    }

    func remount(_ from: String, to: String) throws -> Int {
        let sep = Path.separator
        let fromSlash = from.hasSuffix(sep) ? from : (from + sep)
        let toSlash = to.hasSuffix(sep) ? to : (to + sep)
        let escapeChar = "\\"
        let pattern: String = escapeForLike(fromSlash) + "%"
        let fromLength = fromSlash.count
        try self.connection.run(
            "UPDATE file" +
            " SET path = :to || substr(path, :startindex)" +
            " WHERE path LIKE :pattern ESCAPE :esc",
            [ ":pattern": pattern, ":startindex": fromLength + 1, ":to": toSlash, ":esc": escapeChar ])
        return self.connection.changes
    }

    private func selectFile(_ filePath: String) -> FileRecord? {
        let row = try! connection.pluck(file
            .select([path, size, hash])
            .filter(path == filePath))
        if let row = row {
            return FileRecord(path: row[path], size: row[size], hash: row[hash])
        }
        return nil
    }

    private func createDatabase() throws {
        // PRAGMAS
        try connection.run("PRAGMA case_sensitive_like = ON")

        // CREATE TABLE IF NOT EXISTS file (id INTEGER PRIMARY KEY, size INT NOT NULL, hash TEXT, path TEXT NOT NULL UNIQUE)
        try connection.run(file.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(size)
            t.column(hash)
            t.column(path, unique: true)
        })

        // CREATE INDEX IF NOT EXISTS index_file_on_size_hash
        // ON added (size, hash)
        try connection.run(file.createIndex(size, hash, unique: false, ifNotExists: true))

        try connection.run(
            "CREATE VIEW IF NOT EXISTS candidate" +
            " AS SELECT path, size" +
            " FROM (file, (SELECT size AS duplicated_size FROM file GROUP BY size HAVING COUNT(*) > 1))" +
            " WHERE size == duplicated_size AND hash IS NULL"
        )

        try connection.run(
            "CREATE VIEW IF NOT EXISTS dupe" +
            " AS SELECT id, path, size, hash" +
            " FROM (file, (SELECT size AS duplicated_size, hash AS duplicated_hash FROM file GROUP BY size, hash HAVING COUNT(*) > 1))" +
            " WHERE size == duplicated_size AND hash == duplicated_hash"
        )
    }

    private func createTemporaries() throws {
        // PRAGMAS
        try connection.run("PRAGMA foreign_keys = ON")

        // CREATE TEMP TABLE added (file_id INTEGER PRIMARY KEY NOT NULL REFERENCES file ON DELETE CASCADE, size INT NOT NULL, hash TEXT)
        try connection.run(added.create(temporary: true, ifNotExists: true) { t in
            t.column(file_id, primaryKey: true)
            t.column(size)
            t.column(hash)
            t.foreignKey(file_id, references: file, rowid, update: nil, delete: .cascade)
        })

        // CREATE INDEX IF NOT EXISTS temp.index_added_on_size_hash
        // ON added (size, hash)
        try connection.run(added.createIndex(size, hash, unique: false, ifNotExists: true))

        try connection.run(
            "CREATE TEMP TRIGGER IF NOT EXISTS record_file_added AFTER INSERT ON main.file" +
            "  FOR EACH ROW" +
            "  BEGIN" +
            "    INSERT INTO added (file_id, size, hash) VALUES (NEW.id, NEW.size, NEW.hash);" +
            "  END"
        )

        try connection.run(
            "CREATE TEMP TRIGGER IF NOT EXISTS record_file_updated AFTER UPDATE ON main.file" +
            "  FOR EACH ROW" +
            "  BEGIN" +
            "    UPDATE added SET size = NEW.size, hash = NEW.hash WHERE file_id = NEW.id;" +
            "  END"
        )

        try connection.run(
            "CREATE TEMP VIEW IF NOT EXISTS temp.added_candidate" +
            " AS SELECT DISTINCT candidate.path, candidate.size" +
            " FROM (main.candidate, temp.added)" +
            " WHERE candidate.size == added.size"
        )

        try connection.run(
            "CREATE TEMP VIEW IF NOT EXISTS temp.added_dupe" +
            " AS SELECT DISTINCT path, dupe.size, dupe.hash" +
            " FROM (main.dupe, temp.added)" +
            " WHERE dupe.size == added.size AND dupe.hash == added.hash"
        )
    }

}

func fileRecords<S: Sequence>(_ query: S) -> AnySequence<FileRecord> where S.Element == Row {
    return AnySequence(
        query.lazy.map({ row in
            FileRecord(path: row[path], size: row[size], hash: row[hash])
        })
    )
}

extension DupesDatabase {
    static func open(_ path: String, trackAdditions: Bool = false) -> Swift.Result<DupesDatabase, DupesError> {
        var _db: DupesDatabase?
        let dbPath = "\(Path(path).absolute())"
        do {
            _db = try DupesDatabase(location: .uri(dbPath), trackAdditions: trackAdditions)
        } catch let e {
            return .failure(.Database("\(e)", db: dbPath))
        }
        guard let db = _db else { return .failure(.Database("Failed to open database", db: dbPath)) }

        return .success(db)
    }
}

func escapeForLike(_ path: String, escapeChar esc: Character = "\\") -> String {
    // Always escape the escapes first!
    let escapes = [
        ("\(esc)", "\(esc)\(esc)"),
        ("%", "\(esc)%"),
        ("_", "\(esc)_"),
    ]
    var escaped = path
    for pair in escapes {
        escaped = escaped.replacingOccurrences(of: pair.0, with: pair.1)
    }
    return escaped
}


private let vacuumThreshold = 0.5

extension DupesDatabase {
    func vacuum(force: Bool = false) throws {
        if !force {
            let stats = databasePageStats()
            let freeRatio = Double(stats.freelistCount) / Double(stats.pageCount)
            if freeRatio < vacuumThreshold {
                return
            }
        }
        try connection.run("VACUUM")
    }

    private func scalarInt(_ SQL: String) -> Int? {
        guard let value = try! connection.scalar(SQL) as? Int.Datatype else {
            return nil
        }
        return Int.fromDatatypeValue(value)
    }

    private func databasePageStats() -> (freelistCount: Int, pageCount: Int) {
        let freelistCount = scalarInt("PRAGMA freelist_count")
        let pageCount = scalarInt("PRAGMA page_count")
        return (freelistCount: freelistCount ?? 1, pageCount: pageCount ?? 1)
    }
}
