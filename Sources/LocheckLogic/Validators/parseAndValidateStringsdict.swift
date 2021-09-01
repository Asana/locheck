//
//  parseAndValidateStringsdict.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

func validateKeyPresence(
    basePath: String,
    baseKeys: Set<String>,
    baseLineNumberMap: [String: Int],
    translationPath: String,
    translationKeys: Set<String>,
    translationLineNumberMap: [String: Int],
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    for key in baseKeys.sorted() {
        if !translationKeys.contains(key) {
            problemReporter.report(
                KeyMissingFromTranslation(key: key, language: translationLanguageName),
                path: basePath,
                lineNumber: baseLineNumberMap[key])
        }
    }

    for key in translationKeys.sorted() {
        if !baseKeys.contains(key) {
            problemReporter.report(
                KeyMissingFromBase(key: key),
                path: translationPath,
                lineNumber: translationLineNumberMap[key])
        }
    }
}

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
    let report = { (path: String, problem: Problem) -> Void in
        // lineNumber is nil because we don't have it from SwiftyXMLParser.
        problemReporter.report(problem, path: path, lineNumber: nil)
    }

    validateKeyPresence(
        basePath: baseStringsdict.path,
        baseKeys: Set(baseStringsdict.entries.map(\.key)),
        baseLineNumberMap: [:], // don't have line numbers
        translationPath: translationStringsdict.path,
        translationKeys: Set(translationStringsdict.entries.map(\.key)),
        translationLineNumberMap: [:], // don't have line numbers
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)

    let baseEntries = baseStringsdict.entries.lo_makeDictionary { $0.key }
    for translation in translationStringsdict.entries {
        let translationArgs = translation.getCanonicalArgumentList(
            path: translationStringsdict.path,
            problemReporter: problemReporter)
        guard let baseArgs = baseEntries[translation.key]?
            .getCanonicalArgumentList(path: baseStringsdict.path, problemReporter: problemReporter) else {
            continue // error already logged above
        }

        if translationArgs.count > baseArgs.count {
            let extraArgs = translationArgs.dropFirst(baseArgs.count).map { $0?.specifier ?? "<missing>" }
            report(
                translationStringsdict.path,
                StringsdictEntryHasTooManyArguments(key: translation.key, extraArgs: extraArgs))
        }

        for (i, maybeBaseArg) in baseArgs.enumerated() {
            guard i < translationArgs.count, let translationArg = translationArgs[i] else {
                report(
                    translationStringsdict.path,
                    StringsdictEntryMissingArgument(key: translation.key, position: i + 1))
                continue
            }
            guard let baseArg = maybeBaseArg else {
                report(
                    translationStringsdict.path,
                    StringsdictEntryHasUnverifiableArgument(
                        key: translation.key,
                        position: translationArg.position))
                continue
            }
            if translationArg.specifier != baseArg.specifier {
                report(
                    translationStringsdict.path,
                    StringsdictEntryHasInvalidArgument(
                        key: translation.key,
                        position: translationArg.position,
                        baseSpecifier: baseArg.specifier,
                        translationSpecifier: translationArg.specifier))
            }
        }
    }
}
