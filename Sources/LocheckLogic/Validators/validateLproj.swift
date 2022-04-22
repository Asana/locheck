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
    for file in base.strings {
        guard let counterpart = translation.strings.first(where: { $0.name == file.name }) else {
            problemReporter.report(
                LprojFileMissingFromTranslation(key: file.name, language: translation.name),
                path: file.path,
                lineNumber: 0)
            continue
        }
        parseAndValidateXCStrings(
            base: file,
            translation: counterpart,
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
