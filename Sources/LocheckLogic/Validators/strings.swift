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

    let primaryStrings = primary.lines.enumerated().compactMap {
        LocalizedString(
            string: $0.1,
            file: primary,
            line: $0.0 + 1,
            problemReporter: problemReporter)
    }
    var primaryStringMap = [String: LocalizedString]()
    for localizedString in primaryStrings {
        primaryStringMap[localizedString.key] = localizedString
    }

    validateStrings(
        primaryStrings: primaryStrings,
        secondaryStrings: secondary.lines.enumerated().compactMap {
            LocalizedString(
                string: $0.1,
                file: secondary,
                line: $0.0 + 1,
                primaryStringMap: primaryStringMap,
                problemReporter: problemReporter)
        },
        secondaryFileName: secondaryName,
        problemReporter: problemReporter)
}

func validateStrings(
    primaryStrings: [LocalizedString],
    secondaryStrings: [LocalizedString],
    secondaryFileName: String,
    problemReporter: ProblemReporter) {

    // MARK: Ensure all base strings appear in this translation

    var secondaryStringMap = [String: LocalizedString]()
    for localizedString in secondaryStrings {
        secondaryStringMap[localizedString.key] = localizedString
    }

    for primaryString in primaryStrings {
        if secondaryStringMap[primaryString.key] == nil {
            problemReporter.report(
                .warning,
                path: primaryString.file.path,
                lineNumber: primaryString.line,
                message: "This string is missing from \(secondaryFileName)")
            continue
        }
    }

    // MARK: Validate arguments

    for secondaryString in secondaryStrings {
        let hasSamePositions = Set(secondaryString.baseArguments.map(\.position)) ==
            Set(secondaryString.translationArguments.map(\.position))
        if !hasSamePositions {
            problemReporter.report(
                .error,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Number or value of argument positions do not match")
        }

        let primaryTypes = secondaryString.baseArguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
        let secondaryTypes = secondaryString
            .translationArguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
        if primaryTypes != secondaryTypes {
            problemReporter.report(
                .error,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Specifiers do not match. Original: \(primaryTypes.joined(separator: ",")); translated: \(secondaryTypes.joined(separator: ","))")
        }
    }
}
