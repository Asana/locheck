//
//  validateStringsdict.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

public func validateStringsdict(
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

    let baseKeys = Set(base.entries.map(\.key))
    let translationKeys = Set(translation.entries.map(\.key))

    for key in baseKeys {
        if !translationKeys.contains(key) {
            problemReporter.report(
                .error,
                path: baseFile.path,
                lineNumber: 0,
                message: "Key '\(key)' is missing from \(translationLanguageName)")
        }
    }

    for key in translationKeys {
        if !baseKeys.contains(key) {
            problemReporter.report(
                .error,
                path: translationFile.path,
                lineNumber: 0,
                message: "Key '\(key)' is missing from the base localization")
        }
    }
}
