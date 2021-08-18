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

struct FormatArgument {
    let specifier: String
    let position: Int
}

private extension FormatArgument {
    init(specifier: String, positionString: String) {
        self.specifier = specifier
        position = NumberFormatter().number(from: positionString)!.intValue
    }
}

struct LocalizedString {
    let key: String
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
            .matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
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
        if string.contains("$") {
            return try! NSRegularExpression(pattern: "%(\\d+)\\$([@a-z]+)", options: [])
                .matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
                .compactMap { (match: NSTextCheckingResult) -> FormatArgument? in
                    let groupStrings = match.getGroupStrings(original: string)
                    return FormatArgument(
                        specifier: groupStrings[2],
                        positionString: groupStrings[1])
                }
        } else {
            return try! NSRegularExpression(pattern: "%([@a-z]+)", options: [])
                .matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
                .enumerated()
                .compactMap { (i: Int, match: NSTextCheckingResult) -> FormatArgument? in
                    let groupStrings = match.getGroupStrings(original: string)
                    guard !groupStrings.isEmpty else {
                        problemReporter.logInfo("XXX \(string.debugDescription) \(groupStrings.debugDescription)")
                        return nil
                    }
                    return FormatArgument(
                        specifier: groupStrings.last!,
                        position: i + 1)
                }
        }
    }
}
