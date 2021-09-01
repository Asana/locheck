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

    let baseStringMap = base.strings.lo_makeDictionary(makeKey: \.key)

    for translationString in translation.strings {
        guard let baseString = baseStringMap[translationString.key] else {
            continue // We already threw an error for this in validateKeyPresence()
        }

        let baseArgs = baseString.value.arguments
        let basePhraseArgs = baseString.value.phraseArguments
        let translationArgs = translationString.value.arguments
        let translationPhraseArgs = translationString.value.phraseArguments

        guard translationArgs != baseArgs || translationPhraseArgs != basePhraseArgs else {
            continue // no errors
        }

        let argsMissingFromTranslation = Set(baseArgs.map(\.position)).subtracting(Set(translationArgs.map(\.position)))
        let argsMissingFromBase = Set(translationArgs.map(\.position)).subtracting(Set(baseArgs).map(\.position))
        let phraseMissingFromTranslation = Set(basePhraseArgs).subtracting(Set(translationPhraseArgs))
        let phraseMissingFromBase = Set(translationPhraseArgs).subtracting(Set(basePhraseArgs))

        if !argsMissingFromTranslation.isEmpty {
            problemReporter.report(
                StringHasMissingArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: Array(argsMissingFromTranslation.sorted().map { String($0) })),
                path: translation.path,
                lineNumber: nil)
        }
        if !argsMissingFromBase.isEmpty {
            problemReporter.report(
                StringHasMissingArguments(
                    key: baseString.key,
                    language: translationLanguageName,
                    args: Array(argsMissingFromTranslation.sorted().map { String($0) })),
                path: base.path,
                lineNumber: nil)
        }
        if !phraseMissingFromTranslation.isEmpty {
            problemReporter.report(
                PhraseHasMissingArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: Array(phraseMissingFromTranslation).sorted()),
                path: translation.path,
                lineNumber: nil)
        }
        if !phraseMissingFromBase.isEmpty {
            problemReporter.report(
                PhraseHasMissingArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: Array(phraseMissingFromBase).sorted()),
                path: base.path,
                lineNumber: nil)
        }
    }
}
