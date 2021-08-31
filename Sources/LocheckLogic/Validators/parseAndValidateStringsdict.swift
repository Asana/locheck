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

    let report = { (path: String, problem: Problem) -> Void in
        // lineNumber is zero because we don't have it from SwiftyXMLParser.
        problemReporter.report(problem, path: path, lineNumber: 0)
    }

    let baseKeys = Set(base.entries.map(\.key))
    let translationKeys = Set(translation.entries.map(\.key))

    for key in baseKeys.sorted() {
        if !translationKeys.contains(key) {
            report(baseFile.path, StringsdictKeyMissingFromTranslation(key: key, language: translationLanguageName))
        }
    }

    for key in translationKeys.sorted() {
        if !baseKeys.contains(key) {
            report(translationFile.path, StringsdictKeyMissingFromBase(key: key))
        }
    }

    let baseEntries = base.entries.lo_makeDictionary { $0.key }
    for translation in translation.entries {
        let translationArgs = translation.getCanonicalArgumentList(
            path: translationFile.path,
            problemReporter: problemReporter)
        guard let baseArgs = baseEntries[translation.key]?
            .getCanonicalArgumentList(path: baseFile.path, problemReporter: problemReporter) else {
            continue // error already logged above
        }

        if translationArgs.count > baseArgs.count {
            let extraArgs = translationArgs.dropFirst(baseArgs.count).map { $0?.specifier ?? "<missing>" }
            report(
                translationFile.path,
                StringsdictEntryHasTooManyArguments(key: translation.key, extraArgs: extraArgs))
        }

        for (i, maybeBaseArg) in baseArgs.enumerated() {
            guard i < translationArgs.count, let translationArg = translationArgs[i] else {
                report(
                    translationFile.path,
                    StringsdictEntryMissingArgument(key: translation.key, position: i + 1))
                continue
            }
            guard let baseArg = maybeBaseArg else {
                report(
                    translationFile.path,
                    StringsdictEntryHasUnverifiableArgument(
                        key: translation.key,
                        position: translationArg.position))
                continue
            }
            if translationArg.specifier != baseArg.specifier {
                report(
                    translationFile.path,
                    StringsdictEntryHasInvalidArgument(
                        key: translation.key,
                        position: translationArg.position,
                        baseSpecifier: baseArg.specifier,
                        translationSpecifier: translationArg.specifier))
            }
        }
    }
}
