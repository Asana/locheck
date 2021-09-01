//
//  parseAndValidateAndroidStrings.swift
//
//
//  Created by Steve Landey on 8/31/21.
//

import Files
import Foundation

public func parseAndValidateAndroidStrings(
    base baseFile: File,
    translation translationFile: File,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    guard let base = AndroidStringsFile(path: baseFile.path, problemReporter: problemReporter) else {
        return
    }
    guard let translation = AndroidStringsFile(path: translationFile.path, problemReporter: problemReporter) else {
        return
    }

    validateAndroidStrings(
        base: base,
        translation: translation,
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)
}

func validateAndroidStrings(
    base: AndroidStringsFile,
    translation: AndroidStringsFile,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    validateKeyPresence(
        basePath: base.path,
        baseKeys: Set(base.strings.map(\.key)),
        baseLineNumberMap: [:], // don't have line numbers
        translationPath: translation.path,
        translationKeys: Set(translation.strings.map(\.key)),
        translationLineNumberMap: [:], // don't have line numbers
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)

    validateKeyPresence(
        basePath: base.path,
        baseKeys: Set(base.plurals.map(\.key)),
        baseLineNumberMap: [:], // don't have line numbers
        translationPath: translation.path,
        translationKeys: Set(translation.plurals.map(\.key)),
        translationLineNumberMap: [:], // don't have line numbers
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)
}
