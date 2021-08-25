//
//  LocalizedStringPair.swift
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
        position = Int(positionString)!
    }
}

/// Transform a single string into parsed `FormatSpecifier` objects
private func parseArguments(string: String) -> [FormatArgument] {
    Expressions.argumentRegex
        .lo_matches(in: string)
        .enumerated()
        .compactMap { (i: Int, match: NSTextCheckingResult) -> FormatArgument? in
            guard let specifier = match.lo_getGroup(in: string, named: "specifier") else {
                print("You found a bug! Check this string:", string)
                return nil
            }

            if let positionString = match.lo_getGroup(in: string, named: "position") {
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

/**
 Represents a line from a `.strings` file, like this:

 ```
 "base string with an argument %@" = "translated string with an argument %@";
 ```
 */
struct LocalizedString {
    let string: String
    let arguments: [FormatArgument]
    let file: Filing
    let line: Int?

    init(string: String, file: Filing, line: Int?) {
        self.string = string
        self.arguments = parseArguments(string: string)
        self.file = file
        self.line = line
    }

}

/**
 Represents a line from a `.strings` file, like this:

 ```
 "base string with an argument %@" = "translated string with an argument %@";
 ```
 */
struct LocalizedStringPair {
    let key: String
    let string: String
    let base: LocalizedString
    let translation: LocalizedString
    let file: Filing
    let line: Int

    init?(
        string: String,
        file: Filing,
        line: Int,
        baseStringMap: [String: LocalizedString]? = nil) { // only pass for translation strings
        guard
            let match = Expressions.stringPairRegex.lo_matches(in: string).first,
            let keySequence = match.lo_getGroup(in: string, named: "key")?.dropFirst().dropLast(),
            let valueSequence = match.lo_getGroup(in: string, named: "value")?.dropFirst().dropLast() else {
            return nil
        }
        let key = String(keySequence)
        self.key = key
        self.string = string
        self.file = file
        self.line = line

        // If the base string has its own translation, use that as the key. Sometimes developers omit format specifiers
        // from keys if they provide their own translation in their base language .strings file.
        if let base = baseStringMap?[key] {
            self.base = base
        } else {
            base = LocalizedString(string: key, file: file, line: line)
        }
        translation = LocalizedString(string: String(valueSequence), file: file, line: line)
    }
}
