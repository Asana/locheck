//
//  LocalizedString.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
import Foundation

enum LocalizedStringError: Error {
    case invalidPositionString(String)
}

/// Tiny shim around Files.File to simplify testing
protocol Filing {
    var nameExcludingExtension: String { get }
    var path: String { get }
}

extension File: Filing {}

/// The contents of one "%d" or "%2$@" argument. (These would be
/// `FormatArgument(specifier: "d", position: <automatic>)` and
/// `FormatArgument(specifier: "@", position: 2)`, respectively.)
struct FormatArgument: Equatable {
    let specifier: String
    let position: Int
}

private extension FormatArgument {
    /// Accept position as a string.
    init(specifier: String, positionString: String) {
        self.specifier = specifier
        // ! is safe here because the regular expression only matches digits.
        position = NumberFormatter().number(from: positionString)!.intValue
    }
}

/**
 Represents a line from a `.strings` file, like this:

 ```
 "base string with an argument %@" = "translated string with an argument %@";
 ```
 */
struct LocalizedString {
    let key: String
    let value: String
    let string: String
    let baseArguments: [FormatArgument]
    let translationArguments: [FormatArgument]
    let file: Filing
    let line: Int

    init?(
        string: String,
        file: Filing,
        line: Int,
        baseStringMap: [String: LocalizedString]? = nil) { // only pass for translation strings
        let stringPairRegex = try! NSRegularExpression(
            pattern: Expressions.stringPairExpression,
            options: .anchorsMatchLines)
        guard
            let match = stringPairRegex
            .matches(in: string, options: [], range: NSRange(string.startIndex ..< string.endIndex, in: string))
            .first,
            let keySequence = match.getGroup(in: string, named: "key")?.dropFirst().dropLast(),
            let valueSequence = match.getGroup(in: string, named: "value")?.dropFirst().dropLast() else {
            return nil
        }
        let key = String(keySequence)
        let value = String(valueSequence)
        self.key = key
        self.value = value
        self.string = string
        self.file = file
        self.line = line

        // If the base string has its own translation, use that as the key. Sometimes developers omit format specifiers
        // from keys if they provide their own translation in their base language .strings file.
        if let baseStringMap = baseStringMap, let baseString = baseStringMap[key] {
            baseArguments = baseString.translationArguments
        } else {
            baseArguments = LocalizedString.parseArguments(string: key)
        }
        translationArguments = LocalizedString.parseArguments(string: value)
    }

    /// Transform a single string into parsed `FormatSpecifier` objects
    static func parseArguments(string: String) -> [FormatArgument] {
        try! NSRegularExpression(pattern: Expressions.argumentExpression, options: [])
            .matches(in: string, options: [], range: NSRange(string.startIndex ..< string.endIndex, in: string))
            .enumerated()
            .compactMap { (i: Int, match: NSTextCheckingResult) -> FormatArgument? in
                guard let specifier = match.getGroup(in: string, named: "specifier") else {
                    print("You found a bug! Check this string:", string)
                    return nil
                }

                if let positionString = match.getGroup(in: string, named: "position") {
                    return FormatArgument(
                        specifier: specifier,
                        positionString: positionString)
                } else {
                    return FormatArgument(
                        specifier: specifier,
                        position: i + 1)
                }
            }
    }
}
