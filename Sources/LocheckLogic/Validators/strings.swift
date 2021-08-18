//
//  strings.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

public func parseAndValidateStrings(
    primary: File,
    secondary: File,
    secondaryName: String,
    problemReporter: ProblemReporter) {
    problemReporter.logInfo("Validating \(secondary.path) against \(primary.path)")

    validateStrings(
        primaryStrings: primary.lines.enumerated().compactMap {
            LocalizedString(string: $0.1, file: primary, line: $0.0 + 1, problemReporter: problemReporter)
        },
        secondaryStrings: secondary.lines.enumerated().compactMap {
            LocalizedString(string: $0.1, file: secondary, line: $0.0 + 1, problemReporter: problemReporter)
        },
        secondaryFileName: secondaryName,
        problemReporter: problemReporter)
}

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
    let keyArguments: [FormatArgument]
    let valueArguments: [FormatArgument]
    let file: Filing
    let line: Int

    init?(string: String, file: Filing, line: Int, problemReporter: ProblemReporter) {
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
        keyArguments = LocalizedString.parseArguments(string: key, problemReporter: problemReporter)
        valueArguments = LocalizedString.parseArguments(string: value, problemReporter: problemReporter)
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

func validateStrings(
    primaryStrings: [LocalizedString],
    secondaryStrings: [LocalizedString],
    secondaryFileName: String,
    problemReporter: ProblemReporter) {
    var secondaryStringMap = [String: LocalizedString]()
    for localizedString in secondaryStrings {
        secondaryStringMap[localizedString.key] = localizedString
    }

    for primaryString in primaryStrings {
        guard let secondaryString = secondaryStringMap[primaryString.key] else {
            problemReporter.report(
                .warning,
                path: primaryString.file.path,
                lineNumber: primaryString.line,
                message: "This string is missing from \(secondaryFileName)")
            continue
        }

        let hasSamePositions = Set(primaryString.valueArguments.map(\.position)) ==
            Set(secondaryString.valueArguments.map(\.position))
        if !hasSamePositions {
            problemReporter.report(
                .error,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Number or value of argument positions do not match")
        }

        let primaryTypes = primaryString.valueArguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
        let secondaryTypes = secondaryString
            .valueArguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
        if primaryTypes != secondaryTypes {
            problemReporter.report(
                .error,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Specifiers do not match. Original: \(primaryTypes.joined(separator: ",")); translated: \(secondaryTypes.joined(separator: ","))")
        }
    }
}
