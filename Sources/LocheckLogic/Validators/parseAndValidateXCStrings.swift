//
//  parseAndValidateXCStrings.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

/**
 Directly compare two `.strings` files
 */
public func parseAndValidateXCStrings(
    base: File,
    translation: File,
    baseLanguageName: String,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    let collectLines = { (file: File, isBase: Bool, baseStringMap: [String: FormatString]) -> [LocalizedStringPair] in
        file.lo_getLines(problemReporter: problemReporter)?
            .enumerated()
            .compactMap {
                LocalizedStringPair(
                    string: $0.1,
                    path: file.path,
                    line: $0.0 + 1,
                    basePath: base.path,
                    baseLineFallback: isBase ? $0.0 + 1 : 0,
                    baseStringMap: baseStringMap)
            } ?? []
    }

    // Compare similarly-named files 1-to-1
    let baseStrings: [LocalizedStringPair] = collectLines(base, true, [:])
    guard !baseStrings.isEmpty else { return }

    let baseStringMap = baseStrings.lo_makeDictionary(
        makeKey: \.base.string,
        makeValue: \.translation,
        onDuplicate: { key, value in
            problemReporter.report(
                DuplicateEntries(context: nil, name: key),
                path: value.path,
                lineNumber: value.line)
        })

    let translationStrings = collectLines(translation, false, baseStringMap)
    validateStrings(
        baseStrings: baseStrings,
        translationStrings: translationStrings,
        baseLanguageName: baseLanguageName,
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
    baseLanguageName: String,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    // MARK: Ensure all base strings appear in this translation

    let translationStringMap = translationStrings.lo_makeDictionary(
        makeKey: \.key,
        onDuplicate: { key, value in
            problemReporter.report(
                DuplicateEntries(context: nil, name: key),
                path: value.path,
                lineNumber: value.line)
        })

    for baseString in baseStrings where translationStringMap[baseString.key] == nil {
        problemReporter.report(
            KeyMissingFromTranslation(
                key: baseString.key,
                language: translationLanguageName),
            path: baseString.path,
            lineNumber: baseString.line)
    }
        
    let baseStringsKeys = Set(baseStrings.map(\.key))
        
    var missingInBaseKeys: Set<String> = []
    for translationString in translationStrings where !baseStringsKeys.contains(translationString.key) {
        problemReporter.report(
            KeyMissingFromBase(
                key: translationString.key),
            path: translationString.path,
            lineNumber: translationString.line)
        missingInBaseKeys.insert(translationString.key)
    }

    // MARK: Validate arguments

    for translationString in translationStrings where !missingInBaseKeys.contains(translationString.key) {
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
                    args: args,
                    base: translationString.base.string,
                    translation: translationString.translation.string),
                path: translationString.path,
                lineNumber: translationString.line)
        }

        if !extraArgumentPositions.isEmpty {
            let args = extraArgumentPositions.sorted().map { String($0) }
            problemReporter.report(
                StringHasExtraArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: args,
                    base: translationString.base.string,
                    translation: translationString.translation.string),
                path: translationString.path,
                lineNumber: translationString.line)
        }

        if hasDuplicates {
            problemReporter.report(
                StringHasDuplicateArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    base: translationString.base.string,
                    translation: translationString.translation.string),
                path: translationString.path,
                lineNumber: translationString.line)
        }

        let baseArgs = translationString.base.arguments.sorted(by: { $0.position < $1.position })

        if baseArgs.count > 1 {
            for arg in baseArgs where !arg.isPositionExplicit {
                // This might be reported multiple times, but it's deduped
                problemReporter.report(
                    StringHasImplicitPosition(
                        base: translationString.base.string,
                        translation: translationString.base.string,
                        key: translationString.key,
                        value: translationString.base.string,
                        position: arg.position,
                        language: baseLanguageName,
                        suggestion: arg.asExplicit),
                    path: translationString.base.path,
                    lineNumber: translationString.base.line)
            }
        }

        for arg in translationString.translation.arguments {
            if !arg.isPositionExplicit && translationString.translation.arguments.count > 1 {
                problemReporter.report(
                    StringHasImplicitPosition(
                        base: translationString.base.string,
                        translation: translationString.translation.string,
                        key: translationString.key,
                        value: translationString.translation.string,
                        position: arg.position,
                        language: translationLanguageName,
                        suggestion: arg.asExplicit),
                    path: translationString.path,
                    lineNumber: translationString.line)
            }

            guard let baseArg = baseArgs.first(where: { $0.position == arg.position }) else {
                continue // we already logged an error for this above
            }
            if arg.specifier != baseArg.specifier {
                problemReporter.report(
                    StringHasInvalidArgument(
                        key: translationString.key,
                        language: translationLanguageName,
                        argPosition: arg.position,
                        baseArgSpecifier: baseArg.specifier,
                        argSpecifier: arg.specifier,
                        base: translationString.base.string,
                        translation: translationString.translation.string),
                    path: translationString.path,
                    lineNumber: translationString.line)
            }
        }
    }
}
