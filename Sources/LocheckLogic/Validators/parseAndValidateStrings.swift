//
//  parseAndValidateStrings.swift
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

    let baseStrings = base.lo_lines.enumerated()
        .compactMap {
            LocalizedStringPair(
                string: $0.1,
                path: base.path,
                line: $0.0 + 1)
        }

    var baseStringMap = [String: LocalizedString]()
    for (i, line) in base.lo_lines.enumerated() {
        guard let basePair = LocalizedStringPair(
            string: line,
            path: base.path,
            line: i + 1,
            baseStringMap: [:]) else {
            continue
        }
        baseStringMap[basePair.base.string] = basePair.translation
    }

    validateStrings(
        baseStrings: baseStrings,
        translationStrings: translation.lo_lines.enumerated().compactMap {
            let p = LocalizedStringPair(
                string: $0.1,
                path: translation.path,
                line: $0.0 + 1,
                baseStringMap: baseStringMap)
            return p
        },
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)
}

/**
 Directly compare two lists of already-parsed strings. This is the "interesting" part of the code
 where we look for and report most errors.
 */
func validateStrings(
    baseStrings: [LocalizedStringPair],
    translationStrings: [LocalizedStringPair],
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    // MARK: Ensure all base strings appear in this translation

    let translationStringMap = translationStrings.lo_makeDictionary { $0.key }

    for baseString in baseStrings where translationStringMap[baseString.key] == nil {
        problemReporter.report(
            StringsKeyMissingFromTranslation(
                key: baseString.key,
                language: translationLanguageName),
            path: baseString.path,
            lineNumber: baseString.line)
    }

    // MARK: Validate arguments

    for translationString in translationStrings {
        let baseArgumentPositions = Set(translationString.base.arguments.map(\.position))
        let translationArgumentPositions = Set(translationString.translation.arguments.map(\.position))

        let missingArgumentPositions = baseArgumentPositions.subtracting(translationArgumentPositions)
        let extraArgumentPositions = translationArgumentPositions.subtracting(baseArgumentPositions)
        let hasDuplicates = translationArgumentPositions.count != translationString.translation.arguments.count

        if !missingArgumentPositions.isEmpty {
            let args = missingArgumentPositions.sorted().map { String($0) }
            problemReporter.report(
                StringHasMissingArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: args),
                path: translationString.path,
                lineNumber: translationString.line)
        }

        if !extraArgumentPositions.isEmpty {
            let args = extraArgumentPositions.sorted().map { String($0) }
            problemReporter.report(
                StringHasExtraArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: args),
                path: translationString.path,
                lineNumber: translationString.line)
        }

        if hasDuplicates {
            problemReporter.report(
                StringHasDuplicateArguments(
                    key: translationString.key,
                    language: translationLanguageName),
                path: translationString.path,
                lineNumber: translationString.line)
        }

        let baseArgs = translationString.base.arguments.sorted(by: { $0.position < $1.position })

        for arg in translationString.translation.arguments {
            guard let baseArg = baseArgs.first(where: { $0.position == arg.position }) else {
                continue
            }
            if arg.specifier != baseArg.specifier {
                problemReporter.report(
                    StringHasInvalidArgument(
                        key: translationString.key,
                        language: translationLanguageName,
                        argPosition: arg.position,
                        baseArgSpecifier: baseArg.specifier,
                        argSpecifier: arg.specifier),
                    path: translationString.path,
                    lineNumber: translationString.line)
            }
        }
    }
}
