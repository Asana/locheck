//
//  FormatString.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation

/**
 Represents a string containing format specifiers. This type is shared by the iOS
 and Android validators because they use the same syntax for these kinds of strings.
 */
struct FormatString: Equatable {
    enum Kind: Equatable {
        case native // Xcode, Android 1st party
        case phrase // https://github.com/square/phrase
    }

    let string: String
    let arguments: [FormatArgument]
    let phraseArguments: [String]
    let path: String
    let line: Int
    let kind: Kind

    init(string: String, path: String, line: Int) {
        self.string = string
        self.path = path
        self.line = line

        let nativeArguments = parseNativeArguments(string: string)
        arguments = nativeArguments
        if nativeArguments.isEmpty {
            // Only use Phrase format if native syntax is not present
            phraseArguments = parsePhraseArguments(string: string)
            kind = .phrase
        } else {
            phraseArguments = []
            kind = .native
        }
    }
}

/// Transform a single string into parsed `FormatSpecifier` objects
private func parseNativeArguments(string: String) -> [FormatArgument] {
    var nextImplicitPosition = 1

    return Expressions.nativeArgumentRegex
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
                    positionString: positionString,
                    isPositionExplicit: true)
            } else {
                let implicitPosition = nextImplicitPosition
                // Increment local variable from outside the closure. Impure but convenient.
                nextImplicitPosition += 1
                return FormatArgument(
                    specifier: specifier,
                    position: implicitPosition,
                    isPositionExplicit: false)
            }
        }
}

/// Parse all {foo} expressions out of the given string and return them
private func parsePhraseArguments(string: String) -> [String] {
    Expressions.phraseArgumentRegex
        .lo_matches(in: string)
        .enumerated()
        .compactMap { (i: Int, match: NSTextCheckingResult) -> String? in
            guard let name = match.lo_getGroup(in: string, named: "name") else {
                print("You found a bug! Check this string:", string)
                return nil
            }
            return name
        }
}
