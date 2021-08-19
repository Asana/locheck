//
//  LocalizedString.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
import Foundation

protocol Filing {
    var nameExcludingExtension: String { get }
    var path: String { get }
}

extension File: Filing {}

struct FormatArgument: Equatable {
    let specifier: String
    let position: Int
}

private extension FormatArgument {
    init(specifier: String, positionString: String) {
        self.specifier = specifier
        position = NumberFormatter().number(from: positionString)!.intValue
    }
}

// https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265
private let lengthModifiers: [String] = [
    "h",
    "hh",
    "l",
    "ll",
    "q",
    "L",
    "z",
    "t",
    "j",
]
private let lengthExpression = lengthModifiers.joined(separator: "|")

// https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265
private let specifiers: [String] = [
    // omit %%, it doesn't affect interpolation
    "@",
    "d",
    "D",
    "u",
    "U",
    "x",
    "X",
    "o",
    "O",
    "f",
    "e",
    "E",
    "g",
    "G",
    "c",
    "C",
    "s",
    "S",
    "p",
    "a",
    "A",
    "F",
]
private let specifierExpression = specifiers.joined(separator: "|")

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
        primaryStringMap: [String: LocalizedString]? = nil, // only pass for secondary strings
        problemReporter: ProblemReporter) {
        // https://stackoverflow.com/a/37032779
        let stringPattern = "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\""
        let pattern = "^(\(stringPattern)) = (\(stringPattern));$"
        let stringLiteralRegex = try! NSRegularExpression(
            pattern: pattern,
            options: .anchorsMatchLines)
        guard let strings = stringLiteralRegex
            .matches(in: string, options: [], range: NSRange(string.startIndex ..< string.endIndex, in: string))
            .first?
            .getGroupStrings(original: string) else {
            return nil
        }
        guard strings.count == 2 else {
            return nil
        }
        let key = String(strings[0].dropFirst().dropLast())
        let value = String(strings[1].dropFirst().dropLast())
        self.key = key
        self.value = value
        self.string = string
        self.file = file
        self.line = line

        if let primaryStringMap = primaryStringMap, let primaryString = primaryStringMap[key] {
            baseArguments = primaryString.translationArguments
        } else {
            baseArguments = LocalizedString.parseArguments(string: key, problemReporter: problemReporter)
        }
        translationArguments = LocalizedString.parseArguments(string: value, problemReporter: problemReporter)
    }

    static func parseArguments(string: String, problemReporter: ProblemReporter) -> [FormatArgument] {
        try! NSRegularExpression(pattern: "%((\\d+)\\$)?((\(lengthExpression))?(\(specifierExpression)))", options: [])
            .matches(in: string, options: [], range: NSRange(string.startIndex ..< string.endIndex, in: string))
            .enumerated()
            .compactMap { (i: Int, match: NSTextCheckingResult) -> FormatArgument? in
                let groupStrings = match.getGroupStrings(original: string)

                switch groupStrings.count {
                case 2:
                    return FormatArgument(
                        specifier: groupStrings[1],
                        position: i + 1)
                case 3:
                    return FormatArgument(
                        specifier: groupStrings[1],
                        position: i + 1)
                case 4:
                    return FormatArgument(
                        specifier: groupStrings[1],
                        position: i + 1)
                case 5:
                    return FormatArgument(
                        specifier: groupStrings[3],
                        positionString: groupStrings[2])
                case 6:
                    return FormatArgument(
                        specifier: groupStrings[3],
                        positionString: groupStrings[2])
                default:
                    print("You found a bug! Check this string:", string, groupStrings)
                    return nil
                }
            }
    }
}
