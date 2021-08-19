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
        let secondaryArgumentPositions = Set(secondaryString.translationArguments.map(\.position))
        let primaryArgumentPositions = Set(secondaryString.translationArguments.map(\.position))

        let missingArgumentPositions = primaryArgumentPositions.subtracting(secondaryArgumentPositions)
        let extraArgumentPositions = secondaryArgumentPositions.subtracting(primaryArgumentPositions)
        let hasDuplicates = secondaryArgumentPositions.count != secondaryString.translationArguments.count

        if !missingArgumentPositions.isEmpty {
            let args = missingArgumentPositions.sorted().map { String($0) }.joined(separator: ",")
            problemReporter.report(
                .warning,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Does not include arguments \(args)")
        }

        if !extraArgumentPositions.isEmpty {
            let args = extraArgumentPositions.sorted().map { String($0) }.joined(separator: ",")
            problemReporter.report(
                .error,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Translation includes arguments that don't exist in the source: \(args) (original has \(primaryArgumentPositions); \(secondaryString.value)")
        }

        if hasDuplicates {
            problemReporter.report(
                .warning,
                path: secondaryString.file.path,
                lineNumber: secondaryString.line,
                message: "Some arguments appear more than once in this translation")
        }

        let primaryArgs = secondaryString.baseArguments.sorted(by: { $0.position < $1.position })

        for arg in secondaryString.translationArguments {
            guard let primaryArg = primaryArgs.first(where: { $0.position == arg.position }) else {
                continue
            }
            if arg.specifier != primaryArg.specifier {
                problemReporter.report(
                    .error,
                    path: secondaryString.file.path,
                    lineNumber: secondaryString.line,
                    message: "Specifier for argument \(arg.position) does not match (should be \(primaryArg.specifier), is \(arg.specifier))")
            }
        }
    }
}
