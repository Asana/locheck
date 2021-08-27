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

    let reportError = { (path: String, message: String) -> Void in
        // lineNumber is zero because we don't have it from SwiftyXMLParser.
        problemReporter.report(.error, path: path, lineNumber: 0, message: message)
    }

    let reportWarning = { (path: String, message: String) -> Void in
        problemReporter.report(.warning, path: path, lineNumber: 0, message: message)
    }

    let baseKeys = Set(base.entries.map(\.key))
    let translationKeys = Set(translation.entries.map(\.key))

    for key in baseKeys.sorted() {
        if !translationKeys.contains(key) {
            reportError(baseFile.path, "Key '\(key)' is missing from \(translationLanguageName)")
        }
    }

    for key in translationKeys.sorted() {
        if !baseKeys.contains(key) {
            reportError(translationFile.path, "Key '\(key)' is missing from the base localization")
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
                .joined(separator: ", ")
            reportError(
                translationFile.path,
                "'\(translation.key)' has more arguments than the base language. Extra args: \(extraArgs)")
        }

        for (i, maybeBaseArg) in baseArgs.enumerated() {
            guard i < translationArgs.count, let translationArg = translationArgs[i] else {
                reportWarning(
                    translationFile.path,
                    "'\(translation.key)' is missing argument \(i + 1)")
                continue
            }
            guard let baseArg = maybeBaseArg else {
                reportWarning(
                    translationFile.path,
                    "'\(translation.key)' has an argument at position \(translationArg.position), but the base translation does not, so we can't verify it.")
                continue
            }
            if translationArg.specifier != baseArg.specifier {
                reportError(
                    translationFile.path,
                    "'\(translation.key)' has the wrong specifier at position \(translationArg.position). (Should be '\(baseArg.specifier)', is '\(translationArg.specifier)')")
            }
        }
    }
}
