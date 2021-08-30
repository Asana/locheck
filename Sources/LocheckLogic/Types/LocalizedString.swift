//
//  LocalizedString.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation

/**
 Represents a string containing format specifiers.
 */
struct LocalizedString: Equatable {
    let string: String
    let arguments: [FormatArgument]
    let path: String
    let line: Int?

    init(string: String, path: String, line: Int?) {
        self.string = string
        arguments = parseArguments(string: string)
        self.path = path
        self.line = line
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
                    positionString: positionString,
                    isPositionExplicit: true)
            } else {
                return FormatArgument(
                    specifier: specifier,
                    position: i + 1,
                    isPositionExplicit: false)
            }
        }
}
