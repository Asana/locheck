//
//  strings.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

/**
 Directly compare two `.strings` files
 */
public func parseAndValidateStrings(
    base: File,
    translation: File,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    problemReporter.logInfo("Validating \(translation.path) against \(base.path)")

    let baseStrings = base.lines.enumerated().compactMap {
        LocalizedString(
            string: $0.1,
            file: base,
            line: $0.0 + 1)
    }
    var baseStringMap = [String: LocalizedString]()
    for localizedString in baseStrings {
        baseStringMap[localizedString.key] = localizedString
    }

    validateStrings(
        baseStrings: baseStrings,
        translationStrings: translation.lines.enumerated().compactMap {
            LocalizedString(
                string: $0.1,
                file: translation,
                line: $0.0 + 1,
                baseStringMap: baseStringMap)
        },
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)
}

/**
 Directly compare two lists of already-parsed strings. This is the "interesting" part of the code
 where we look for and report most errors.
 */
func validateStrings(
    baseStrings: [LocalizedString],
    translationStrings: [LocalizedString],
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    // MARK: Ensure all base strings appear in this translation

    var translationStringMap = [String: LocalizedString]()
    for localizedString in translationStrings {
        translationStringMap[localizedString.key] = localizedString
    }

    for baseString in baseStrings {
        if translationStringMap[baseString.key] == nil {
            problemReporter.report(
                .warning,
                path: baseString.file.path,
                lineNumber: baseString.line,
                message: "This string is missing from \(translationLanguageName)")
            continue
        }
    }

    // MARK: Validate arguments

    for translationString in translationStrings {
        let baseArgumentPositions = Set(translationString.baseArguments.map(\.position))
        let translationArgumentPositions = Set(translationString.translationArguments.map(\.position))

        let missingArgumentPositions = baseArgumentPositions.subtracting(translationArgumentPositions)
        let extraArgumentPositions = translationArgumentPositions.subtracting(baseArgumentPositions)
        let hasDuplicates = translationArgumentPositions.count != translationString.translationArguments.count

        if !missingArgumentPositions.isEmpty {
            let args = missingArgumentPositions.sorted().map { String($0) }.joined(separator: ",")
            problemReporter.report(
                .warning,
                path: translationString.file.path,
                lineNumber: translationString.line,
                message: "Does not include arguments \(args)")
        }

        if !extraArgumentPositions.isEmpty {
            let args = extraArgumentPositions.sorted().map { String($0) }.joined(separator: ",")
            problemReporter.report(
                .error,
                path: translationString.file.path,
                lineNumber: translationString.line,
                message: "Translation includes arguments that don't exist in the source: \(args) (original has \(baseArgumentPositions); \(translationString.value)")
        }

        if hasDuplicates {
            problemReporter.report(
                .warning,
                path: translationString.file.path,
                lineNumber: translationString.line,
                message: "Some arguments appear more than once in this translation")
        }

        let baseArgs = translationString.baseArguments.sorted(by: { $0.position < $1.position })

        for arg in translationString.translationArguments {
            guard let baseArg = baseArgs.first(where: { $0.position == arg.position }) else {
                continue
            }
            if arg.specifier != baseArg.specifier {
                problemReporter.report(
                    .error,
                    path: translationString.file.path,
                    lineNumber: translationString.line,
                    message: "Specifier for argument \(arg.position) does not match (should be \(baseArg.specifier), is \(arg.specifier))")
            }
        }
    }
}
