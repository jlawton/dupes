//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

extension ExpressionType where UnderlyingType : Number {

    /// Builds a copy of the expression wrapped with the `abs` function.
    ///
    ///     let x = Expression<Int>("x")
    ///     x.absoluteValue
    ///     // abs("x")
    ///
    /// - Returns: A copy of the expression wrapped with the `abs` function.
    public var absoluteValue : Expression<UnderlyingType> {
        return "abs".wrap(self)
    }

}

extension ExpressionType where UnderlyingType : _OptionalType, UnderlyingType.WrappedType : Number {

    /// Builds a copy of the expression wrapped with the `abs` function.
    ///
    ///     let x = Expression<Int?>("x")
    ///     x.absoluteValue
    ///     // abs("x")
    ///
    /// - Returns: A copy of the expression wrapped with the `abs` function.
    public var absoluteValue : Expression<UnderlyingType> {
        return "abs".wrap(self)
    }

}

extension ExpressionType where UnderlyingType == Double {

    /// Builds a copy of the expression wrapped with the `round` function.
    ///
    ///     let salary = Expression<Double>("salary")
    ///     salary.round()
    ///     // round("salary")
    ///     salary.round(2)
    ///     // round("salary", 2)
    ///
    /// - Returns: A copy of the expression wrapped with the `round` function.
    @warn_unused_result public func round(precision: Int? = nil) -> Expression<UnderlyingType> {
        guard let precision = precision else {
            return wrap([self])
        }
        return wrap([self, Int(precision)])
    }

}

extension ExpressionType where UnderlyingType == Double? {

    /// Builds a copy of the expression wrapped with the `round` function.
    ///
    ///     let salary = Expression<Double>("salary")
    ///     salary.round()
    ///     // round("salary")
    ///     salary.round(2)
    ///     // round("salary", 2)
    ///
    /// - Returns: A copy of the expression wrapped with the `round` function.
    @warn_unused_result public func round(precision: Int? = nil) -> Expression<UnderlyingType> {
        guard let precision = precision else {
            return wrap(self)
        }
        return wrap([self, Int(precision)])
    }

}

extension ExpressionType where UnderlyingType : Value, UnderlyingType.Datatype == Int64 {

    /// Builds an expression representing the `random` function.
    ///
    ///     Expression<Int>.random()
    ///     // random()
    ///
    /// - Returns: An expression calling the `random` function.
    @warn_unused_result public static func random() -> Expression<UnderlyingType> {
        return "random".wrap([])
    }

}

extension ExpressionType where UnderlyingType == NSData {

    /// Builds an expression representing the `randomblob` function.
    ///
    ///     Expression<Int>.random(16)
    ///     // randomblob(16)
    ///
    /// - Parameter length: Length in bytes.
    ///
    /// - Returns: An expression calling the `randomblob` function.
    @warn_unused_result public static func random(length: Int) -> Expression<UnderlyingType> {
        return "randomblob".wrap([])
    }

    /// Builds an expression representing the `zeroblob` function.
    ///
    ///     Expression<Int>.allZeros(16)
    ///     // zeroblob(16)
    ///
    /// - Parameter length: Length in bytes.
    ///
    /// - Returns: An expression calling the `zeroblob` function.
    @warn_unused_result public static func allZeros(length: Int) -> Expression<UnderlyingType> {
        return "zeroblob".wrap([])
    }

    /// Builds a copy of the expression wrapped with the `length` function.
    ///
    ///     let data = Expression<NSData>("data")
    ///     data.length
    ///     // length("data")
    ///
    /// - Returns: A copy of the expression wrapped with the `length` function.
    public var length: Expression<Int> {
        return wrap(self)
    }

}

extension ExpressionType where UnderlyingType == NSData? {

    /// Builds a copy of the expression wrapped with the `length` function.
    ///
    ///     let data = Expression<NSData?>("data")
    ///     data.length
    ///     // length("data")
    ///
    /// - Returns: A copy of the expression wrapped with the `length` function.
    public var length: Expression<Int?> {
        return wrap(self)
    }

}

extension ExpressionType where UnderlyingType == String {

    /// Builds a copy of the expression wrapped with the `length` function.
    ///
    ///     let name = Expression<String>("name")
    ///     name.length
    ///     // length("name")
    ///
    /// - Returns: A copy of the expression wrapped with the `length` function.
    public var length: Expression<Int> {
        return wrap(self)
    }

    /// Builds a copy of the expression wrapped with the `lower` function.
    ///
    ///     let name = Expression<String>("name")
    ///     name.lowercaseString
    ///     // lower("name")
    ///
    /// - Returns: A copy of the expression wrapped with the `lower` function.
    public var lowercaseString: Expression<UnderlyingType> {
        return "lower".wrap(self)
    }

    /// Builds a copy of the expression wrapped with the `upper` function.
    ///
    ///     let name = Expression<String>("name")
    ///     name.uppercaseString
    ///     // lower("name")
    ///
    /// - Returns: A copy of the expression wrapped with the `upper` function.
    public var uppercaseString: Expression<UnderlyingType> {
        return "upper".wrap(self)
    }

    /// Builds a copy of the expression appended with a `LIKE` query against the
    /// given pattern.
    ///
    ///     let email = Expression<String>("email")
    ///     email.like("%@example.com")
    ///     // "email" LIKE '%@example.com'
    ///     email.like("99\\%@%", escape: "\\")
    ///     // "email" LIKE '99\%@%' ESCAPE '\'
    ///
    /// - Parameters:
    ///
    ///   - pattern: A pattern to match.
    ///
    ///   - escape: An (optional) character designated for escaping
    ///     pattern-matching characters (*i.e.*, the `%` and `_` characters).
    ///
    /// - Returns: A copy of the expression appended with a `LIKE` query against
    ///   the given pattern.
    @warn_unused_result public func like(pattern: String, escape character: Character? = nil) -> Expression<Bool> {
        guard let character = character else {
            return "LIKE".infix(self, pattern)
        }
        return Expression("(\(template) LIKE ? ESCAPE ?)", bindings + [pattern, String(character)])
    }

    /// Builds a copy of the expression appended with a `GLOB` query against the
    /// given pattern.
    ///
    ///     let path = Expression<String>("path")
    ///     path.glob("*.png")
    ///     // "path" GLOB '*.png'
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression appended with a `GLOB` query against
    ///   the given pattern.
    @warn_unused_result public func glob(pattern: String) -> Expression<Bool> {
        return "GLOB".infix(self, pattern)
    }

    /// Builds a copy of the expression appended with a `MATCH` query against
    /// the given pattern.
    ///
    ///     let title = Expression<String>("title")
    ///     title.match("swift AND programming")
    ///     // "title" MATCH 'swift AND programming'
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression appended with a `MATCH` query
    ///   against the given pattern.
    @warn_unused_result public func match(pattern: String) -> Expression<Bool> {
        return "MATCH".infix(self, pattern)
    }

    /// Builds a copy of the expression appended with a `REGEXP` query against
    /// the given pattern.
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression appended with a `REGEXP` query
    ///   against the given pattern.
    @warn_unused_result public func regexp(pattern: String) -> Expression<Bool> {
        return "REGEXP".infix(self, pattern)
    }

    /// Builds a copy of the expression appended with a `COLLATE` clause with
    /// the given sequence.
    ///
    ///     let name = Expression<String>("name")
    ///     name.collate(.Nocase)
    ///     // "name" COLLATE NOCASE
    ///
    /// - Parameter collation: A collating sequence.
    ///
    /// - Returns: A copy of the expression appended with a `COLLATE` clause
    ///   with the given sequence.
    @warn_unused_result public func collate(collation: Collation) -> Expression<UnderlyingType> {
        return "COLLATE".infix(self, collation)
    }

    /// Builds a copy of the expression wrapped with the `ltrim` function.
    ///
    ///     let name = Expression<String>("name")
    ///     name.ltrim()
    ///     // ltrim("name")
    ///     name.ltrim([" ", "\t"])
    ///     // ltrim("name", ' \t')
    ///
    /// - Parameter characters: A set of characters to trim.
    ///
    /// - Returns: A copy of the expression wrapped with the `ltrim` function.
    @warn_unused_result public func ltrim(characters: Set<Character>? = nil) -> Expression<UnderlyingType> {
        guard let characters = characters else {
            return wrap(self)
        }
        return wrap([self, String(characters)])
    }

    /// Builds a copy of the expression wrapped with the `rtrim` function.
    ///
    ///     let name = Expression<String>("name")
    ///     name.rtrim()
    ///     // rtrim("name")
    ///     name.rtrim([" ", "\t"])
    ///     // rtrim("name", ' \t')
    ///
    /// - Parameter characters: A set of characters to trim.
    ///
    /// - Returns: A copy of the expression wrapped with the `rtrim` function.
    @warn_unused_result public func rtrim(characters: Set<Character>? = nil) -> Expression<UnderlyingType> {
        guard let characters = characters else {
            return wrap(self)
        }
        return wrap([self, String(characters)])
    }

    /// Builds a copy of the expression wrapped with the `trim` function.
    ///
    ///     let name = Expression<String>("name")
    ///     name.trim()
    ///     // trim("name")
    ///     name.trim([" ", "\t"])
    ///     // trim("name", ' \t')
    ///
    /// - Parameter characters: A set of characters to trim.
    ///
    /// - Returns: A copy of the expression wrapped with the `trim` function.
    @warn_unused_result public func trim(characters: Set<Character>? = nil) -> Expression<UnderlyingType> {
        guard let characters = characters else {
            return wrap([self])
        }
        return wrap([self, String(characters)])
    }

    /// Builds a copy of the expression wrapped with the `replace` function.
    ///
    ///     let email = Expression<String>("email")
    ///     email.replace("@mac.com", with: "@icloud.com")
    ///     // replace("email", '@mac.com', '@icloud.com')
    ///
    /// - Parameters:
    ///
    ///   - pattern: A pattern to match.
    ///
    ///   - replacement: The replacement string.
    ///
    /// - Returns: A copy of the expression wrapped with the `replace` function.
    @warn_unused_result public func replace(pattern: String, with replacement: String) -> Expression<UnderlyingType> {
        return "replace".wrap([self, pattern, replacement])
    }

    @warn_unused_result public func substring(location: Int, length: Int? = nil) -> Expression<UnderlyingType> {
        guard let length = length else {
            return "substr".wrap([self, location])
        }
        return "substr".wrap([self, location, length])
    }

    public subscript(range: Range<Int>) -> Expression<UnderlyingType> {
        return substring(range.startIndex, length: range.endIndex - range.startIndex)
    }

}

extension ExpressionType where UnderlyingType == String? {

    /// Builds a copy of the expression wrapped with the `length` function.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.length
    ///     // length("name")
    ///
    /// - Returns: A copy of the expression wrapped with the `length` function.
    public var length: Expression<Int?> {
        return wrap(self)
    }

    /// Builds a copy of the expression wrapped with the `lower` function.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.lowercaseString
    ///     // lower("name")
    ///
    /// - Returns: A copy of the expression wrapped with the `lower` function.
    public var lowercaseString: Expression<UnderlyingType> {
        return "lower".wrap(self)
    }

    /// Builds a copy of the expression wrapped with the `upper` function.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.uppercaseString
    ///     // lower("name")
    ///
    /// - Returns: A copy of the expression wrapped with the `upper` function.
    public var uppercaseString: Expression<UnderlyingType> {
        return "upper".wrap(self)
    }

    /// Builds a copy of the expression appended with a `LIKE` query against the
    /// given pattern.
    ///
    ///     let email = Expression<String?>("email")
    ///     email.like("%@example.com")
    ///     // "email" LIKE '%@example.com'
    ///     email.like("99\\%@%", escape: "\\")
    ///     // "email" LIKE '99\%@%' ESCAPE '\'
    ///
    /// - Parameters:
    ///
    ///   - pattern: A pattern to match.
    ///
    ///   - escape: An (optional) character designated for escaping
    ///     pattern-matching characters (*i.e.*, the `%` and `_` characters).
    ///
    /// - Returns: A copy of the expression appended with a `LIKE` query against
    ///   the given pattern.
    @warn_unused_result public func like(pattern: String, escape character: Character? = nil) -> Expression<Bool?> {
        guard let character = character else {
            return "LIKE".infix(self, pattern)
        }
        return Expression("(\(template) LIKE ? ESCAPE ?)", bindings + [pattern, String(character)])
    }

    /// Builds a copy of the expression appended with a `GLOB` query against the
    /// given pattern.
    ///
    ///     let path = Expression<String?>("path")
    ///     path.glob("*.png")
    ///     // "path" GLOB '*.png'
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression appended with a `GLOB` query against
    ///   the given pattern.
    @warn_unused_result public func glob(pattern: String) -> Expression<Bool?> {
        return "GLOB".infix(self, pattern)
    }

    /// Builds a copy of the expression appended with a `MATCH` query against
    /// the given pattern.
    ///
    ///     let title = Expression<String?>("title")
    ///     title.match("swift AND programming")
    ///     // "title" MATCH 'swift AND programming'
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression appended with a `MATCH` query
    ///   against the given pattern.
    @warn_unused_result public func match(pattern: String) -> Expression<Bool> {
        return "MATCH".infix(self, pattern)
    }

    /// Builds a copy of the expression appended with a `REGEXP` query against
    /// the given pattern.
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression appended with a `REGEXP` query
    ///   against the given pattern.
    @warn_unused_result public func regexp(pattern: String) -> Expression<Bool?> {
        return "REGEXP".infix(self, pattern)
    }

    /// Builds a copy of the expression appended with a `COLLATE` clause with
    /// the given sequence.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.collate(.Nocase)
    ///     // "name" COLLATE NOCASE
    ///
    /// - Parameter collation: A collating sequence.
    ///
    /// - Returns: A copy of the expression appended with a `COLLATE` clause
    ///   with the given sequence.
    @warn_unused_result public func collate(collation: Collation) -> Expression<UnderlyingType> {
        return "COLLATE".infix(self, collation)
    }

    /// Builds a copy of the expression wrapped with the `ltrim` function.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.ltrim()
    ///     // ltrim("name")
    ///     name.ltrim([" ", "\t"])
    ///     // ltrim("name", ' \t')
    ///
    /// - Parameter characters: A set of characters to trim.
    ///
    /// - Returns: A copy of the expression wrapped with the `ltrim` function.
    @warn_unused_result public func ltrim(characters: Set<Character>? = nil) -> Expression<UnderlyingType> {
        guard let characters = characters else {
            return wrap(self)
        }
        return wrap([self, String(characters)])
    }

    /// Builds a copy of the expression wrapped with the `rtrim` function.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.rtrim()
    ///     // rtrim("name")
    ///     name.rtrim([" ", "\t"])
    ///     // rtrim("name", ' \t')
    ///
    /// - Parameter characters: A set of characters to trim.
    ///
    /// - Returns: A copy of the expression wrapped with the `rtrim` function.
    @warn_unused_result public func rtrim(characters: Set<Character>? = nil) -> Expression<UnderlyingType> {
        guard let characters = characters else {
            return wrap(self)
        }
        return wrap([self, String(characters)])
    }

    /// Builds a copy of the expression wrapped with the `trim` function.
    ///
    ///     let name = Expression<String?>("name")
    ///     name.trim()
    ///     // trim("name")
    ///     name.trim([" ", "\t"])
    ///     // trim("name", ' \t')
    ///
    /// - Parameter characters: A set of characters to trim.
    ///
    /// - Returns: A copy of the expression wrapped with the `trim` function.
    @warn_unused_result public func trim(characters: Set<Character>? = nil) -> Expression<UnderlyingType> {
        guard let characters = characters else {
            return wrap(self)
        }
        return wrap([self, String(characters)])
    }

    /// Builds a copy of the expression wrapped with the `replace` function.
    ///
    ///     let email = Expression<String?>("email")
    ///     email.replace("@mac.com", with: "@icloud.com")
    ///     // replace("email", '@mac.com', '@icloud.com')
    ///
    /// - Parameters:
    ///
    ///   - pattern: A pattern to match.
    ///
    ///   - replacement: The replacement string.
    ///
    /// - Returns: A copy of the expression wrapped with the `replace` function.
    @warn_unused_result public func replace(pattern: String, with replacement: String) -> Expression<UnderlyingType> {
        return "replace".wrap([self, pattern, replacement])
    }

    /// Builds a copy of the expression wrapped with the `substr` function.
    ///
    ///     let title = Expression<String?>("title")
    ///     title.substr(-100)
    ///     // substr("title", -100)
    ///     title.substr(0, length: 100)
    ///     // substr("title", 0, 100)
    ///
    /// - Parameters:
    ///
    ///   - location: The substring’s start index.
    ///
    ///   - length: An optional substring length.
    ///
    /// - Returns: A copy of the expression wrapped with the `substr` function.
    @warn_unused_result public func substring(location: Int, length: Int? = nil) -> Expression<UnderlyingType> {
        guard let length = length else {
            return "substr".wrap([self, location])
        }
        return "substr".wrap([self, location, length])
    }

    /// Builds a copy of the expression wrapped with the `substr` function.
    ///
    ///     let title = Expression<String?>("title")
    ///     title[0..<100]
    ///     // substr("title", 0, 100)
    ///
    /// - Parameter range: The character index range of the substring.
    ///
    /// - Returns: A copy of the expression wrapped with the `substr` function.
    public subscript(range: Range<Int>) -> Expression<UnderlyingType> {
        return substring(range.startIndex, length: range.endIndex - range.startIndex)
    }

}

extension CollectionType where Generator.Element : Value, Index.Distance == Int {

    /// Builds a copy of the expression prepended with an `IN` check against the
    /// collection.
    ///
    ///     let name = Expression<String>("name")
    ///     ["alice", "betty"].contains(name)
    ///     // "name" IN ('alice', 'betty')
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression prepended with an `IN` check against
    ///   the collection.
    @warn_unused_result public func contains(expression: Expression<Generator.Element>) -> Expression<Bool> {
        let templates = [String](count: count, repeatedValue: "?").joinWithSeparator(", ")
        return "IN".infix(expression, Expression<Void>("(\(templates))", map { $0.datatypeValue }))
    }

    /// Builds a copy of the expression prepended with an `IN` check against the
    /// collection.
    ///
    ///     let name = Expression<String?>("name")
    ///     ["alice", "betty"].contains(name)
    ///     // "name" IN ('alice', 'betty')
    ///
    /// - Parameter pattern: A pattern to match.
    ///
    /// - Returns: A copy of the expression prepended with an `IN` check against
    ///   the collection.
    @warn_unused_result public func contains(expression: Expression<Generator.Element?>) -> Expression<Bool?> {
        let templates = [String](count: count, repeatedValue: "?").joinWithSeparator(", ")
        return "IN".infix(expression, Expression<Void>("(\(templates))", map { $0.datatypeValue }))
    }

}

/// Builds a copy of the given expressions wrapped with the `ifnull` function.
///
///     let name = Expression<String?>("name")
///     name ?? "An Anonymous Coward"
///     // ifnull("name", 'An Anonymous Coward')
///
/// - Parameters:
///
///   - optional: An optional expression.
///
///   - defaultValue: A fallback value for when the optional expression is
///     `nil`.
///
/// - Returns: A copy of the given expressions wrapped with the `ifnull`
///   function.
public func ??<V : Value>(optional: Expression<V?>, defaultValue: V) -> Expression<V> {
    return "ifnull".wrap([optional, defaultValue])
}

/// Builds a copy of the given expressions wrapped with the `ifnull` function.
///
///     let nick = Expression<String?>("nick")
///     let name = Expression<String>("name")
///     nick ?? name
///     // ifnull("nick", "name")
///
/// - Parameters:
///
///   - optional: An optional expression.
///
///   - defaultValue: A fallback expression for when the optional expression is
///     `nil`.
///
/// - Returns: A copy of the given expressions wrapped with the `ifnull`
///   function.
public func ??<V : Value>(optional: Expression<V?>, defaultValue: Expression<V>) -> Expression<V> {
    return "ifnull".wrap([optional, defaultValue])
}

/// Builds a copy of the given expressions wrapped with the `ifnull` function.
///
///     let nick = Expression<String?>("nick")
///     let name = Expression<String?>("name")
///     nick ?? name
///     // ifnull("nick", "name")
///
/// - Parameters:
///
///   - optional: An optional expression.
///
///   - defaultValue: A fallback expression for when the optional expression is
///     `nil`.
///
/// - Returns: A copy of the given expressions wrapped with the `ifnull`
///   function.
public func ??<V : Value>(optional: Expression<V?>, defaultValue: Expression<V?>) -> Expression<V> {
    return "ifnull".wrap([optional, defaultValue])
}
