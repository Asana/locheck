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
    guard
        let base = AndroidStringsFile(path: baseFile.path, problemReporter: problemReporter),
        let translation = AndroidStringsFile(path: translationFile.path, problemReporter: problemReporter) else {
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
        baseLineNumberMap: base.strings.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationPath: translation.path,
        translationKeys: Set(translation.strings.map(\.key)),
        translationLineNumberMap: translation.strings.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)

    validateKeyPresence(
        basePath: base.path,
        baseKeys: Set(base.plurals.map(\.key)),
        baseLineNumberMap: base.plurals.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationPath: translation.path,
        translationKeys: Set(translation.plurals.map(\.key)),
        translationLineNumberMap: translation.plurals.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)

    validateKeyPresence(
        basePath: base.path,
        baseKeys: Set(base.stringArrays.map(\.key)),
        baseLineNumberMap: base.stringArrays.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationPath: translation.path,
        translationKeys: Set(translation.stringArrays.map(\.key)),
        translationLineNumberMap: translation.stringArrays.lo_makeDictionary(makeKey: \.key, makeValue: \.line),
        translationLanguageName: translationLanguageName,
        problemReporter: problemReporter)

    let baseStringMap = base.strings.lo_makeDictionary(
        makeKey: \.key,
        onDuplicate: { key, value in
            problemReporter.report(
                DuplicateEntries(context: nil, name: key),
                path: base.path,
                lineNumber: value.line)
        })
    let baseStringArrayMap = base.stringArrays.lo_makeDictionary(makeKey: \.key)
    var seenTranslationKeys = Set<String>()

    for translationString in translation.strings {
        guard let baseString = baseStringMap[translationString.key] else {
            continue // We already threw an error for this in validateKeyPresence()
        }

        if seenTranslationKeys.contains(translationString.key) {
            problemReporter.report(
                DuplicateEntries(context: nil, name: translationString.key),
                path: translation.path,
                lineNumber: translationString.line)
        }
        seenTranslationKeys.insert(translationString.key)

        let baseArgs = baseString.value.arguments.sorted(by: { $0.position < $1.position })
        let basePhraseArgs = baseString.value.phraseArguments
        let translationArgs = translationString.value.arguments.sorted(by: { $0.position < $1.position })
        let translationPhraseArgs = translationString.value.phraseArguments

        guard translationArgs != baseArgs || translationPhraseArgs != basePhraseArgs else {
            continue // no errors
        }

        if !translationPhraseArgs.isEmpty && !translationArgs.isEmpty {
            problemReporter.report(
                PhraseAndNativeArgumentsAreBothPresent(
                    key: translationString.key,
                    base: baseString.value.string,
                    translation: translationString.value.string),
                path: translation.path,
                lineNumber: translationString.line)
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
                    args: Array(argsMissingFromTranslation.sorted().map { String($0) }),
                    base: baseString.value.string,
                    translation: translationString.value.string),
                path: translation.path,
                lineNumber: translationString.line)
        }
        if !argsMissingFromBase.isEmpty {
            problemReporter.report(
                StringHasExtraArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: Array(argsMissingFromTranslation.sorted().map { String($0) }),
                    base: baseString.value.string,
                    translation: translationString.value.string),
                path: translation.path,
                lineNumber: baseString.line)
        }
        if !phraseMissingFromTranslation.isEmpty {
            problemReporter.report(
                PhraseHasMissingArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: Array(phraseMissingFromTranslation).sorted(),
                    base: baseString.value.string,
                    translation: translationString.value.string),
                path: translation.path,
                lineNumber: translationString.line)
        }
        if !phraseMissingFromBase.isEmpty {
            problemReporter.report(
                PhraseHasExtraArguments(
                    key: translationString.key,
                    language: translationLanguageName,
                    args: Array(phraseMissingFromBase).sorted(),
                    base: baseString.value.string,
                    translation: translationString.value.string),
                path: translation.path,
                lineNumber: baseString.line)
        }

        for arg in translationString.value.arguments {
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
                        base: baseString.value.string,
                        translation: translationString.value.string),
                    path: translation.path,
                    lineNumber: translationString.line)
            }
        }
    }

    for translationStringArray in translation.stringArrays {
        guard let baseStringArray = baseStringArrayMap[translationStringArray.key] else {
            continue // We already threw an error for this in validateKeyPresence()
        }

        if translationStringArray.values.count != baseStringArray.values.count {
            problemReporter.report(
                StringArrayItemCountMismatch(
                    key: translationStringArray.key,
                    language: translationLanguageName,
                    countBase: baseStringArray.values.count,
                    countTranslation: translationStringArray.values.count),
                path: translation.path,
                lineNumber: translationStringArray.line)
        }
    }
}
