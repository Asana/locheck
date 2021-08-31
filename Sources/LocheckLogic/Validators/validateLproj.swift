//
//  validateLproj.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

/**
 Directly compare `.strings` files with the same name across two `.lproj` files
 */
public func validateLproj(base: LprojFiles, translation: LprojFiles, problemReporter: ProblemReporter) {
    for stringsFile in base.strings {
        guard let translationStringsFile = translation.strings.first(where: { $0.name == stringsFile.name }) else {
            problemReporter.report(
                LprojFileMissingFromTranslation(
                    key: stringsFile.name,
                    language: translation.name),
                path: stringsFile.path,
                lineNumber: 0)
            continue
        }
        parseAndValidateXCStrings(
            base: stringsFile,
            translation: translationStringsFile,
            translationLanguageName: translation.name,
            problemReporter: problemReporter)
    }

    for baseStringsdictFile in base.stringsdict {
        guard let translationStringsdictFile = translation.stringsdict
            .first(where: { $0.name == baseStringsdictFile.name })
        else {
            problemReporter.report(
                LprojFileMissingFromTranslation(
                    key: baseStringsdictFile.name,
                    language: translation.name),
                path: baseStringsdictFile.path,
                lineNumber: 0)
            continue
        }
        parseAndValidateStringsdict(
            base: baseStringsdictFile,
            translation: translationStringsdictFile,
            translationLanguageName: translation.name,
            problemReporter: problemReporter)
    }
}
