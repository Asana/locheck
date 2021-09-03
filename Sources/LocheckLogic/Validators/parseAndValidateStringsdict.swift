//
//  parseAndValidateStringsdict.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

public func parseAndValidateStringsdict(
    base baseFile: File,
    translation translationFile: File,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    guard let base = Stringsdict(path: baseFile.path, problemReporter: problemReporter) else {
        return
    }
    guard let translation = Stringsdict(path: translationFile.path, problemReporter: problemReporter) else {
        return
    }
    validateStringsdict(
        base: base,
        translation: translation,
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)
}

func validateStringsdict(
    base baseStringsdict: Stringsdict,
    translation translationStringsdict: Stringsdict,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    validateKeyPresence(
        basePath: baseStringsdict.path,
        baseKeys: Set(baseStringsdict.entries.map(\.key)),
        baseLineNumberMap: baseStringsdict.entries.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationPath: translationStringsdict.path,
        translationKeys: Set(translationStringsdict.entries.map(\.key)),
        translationLineNumberMap: translationStringsdict.entries.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)

    let baseArgLists = baseStringsdict.entries.lo_makeDictionary(
        makeKey: \.key,
        makeValue: { $0.getCanonicalArgumentList(problemReporter: problemReporter) })
    for translation in translationStringsdict.entries {
        let translationArgs = translation.getCanonicalArgumentList(
            problemReporter: problemReporter)
        guard let baseArgs = baseArgLists[translation.key] else {
            continue // error already logged above
        }

        if translationArgs.count > baseArgs.count {
            let extraArgs = translationArgs.dropFirst(baseArgs.count).map { $0?.specifier ?? "<missing>" }
            problemReporter.report(
                StringsdictEntryHasTooManyArguments(key: translation.key, extraArgs: extraArgs),
                path: translationStringsdict.path,
                lineNumber: translation.line)
        }

        for (i, maybeBaseArg) in baseArgs.enumerated() {
            guard i < translationArgs.count, let translationArg = translationArgs[i] else {
                problemReporter.report(
                    StringsdictEntryMissingArgument(key: translation.key, position: i + 1),
                    path: translationStringsdict.path,
                    lineNumber: translation.line)
                continue
            }
            guard let baseArg = maybeBaseArg else {
                problemReporter.report(
                    StringsdictEntryHasUnverifiableArgument(
                        key: translation.key,
                        position: translationArg.position),
                    path: translationStringsdict.path,
                    lineNumber: translation.line)
                continue
            }
            if translationArg.specifier != baseArg.specifier {
                problemReporter.report(
                    StringsdictEntryHasInvalidArgument(
                        key: translation.key,
                        position: translationArg.position,
                        baseSpecifier: baseArg.specifier,
                        translationSpecifier: translationArg.specifier),
                    path: translationStringsdict.path,
                    lineNumber: translation.line)
            }
        }
    }
}
