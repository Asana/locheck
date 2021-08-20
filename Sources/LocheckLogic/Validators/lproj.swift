//
//  lproj.swift
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
                .error,
                path: stringsFile.name,
                lineNumber: 0,
                message: "\(stringsFile.name) missing from translation \(translation.name)")
            continue
        }
        parseAndValidateStrings(
            base: stringsFile,
            translation: translationStringsFile,
            translationLanguageName: translation.name,
            problemReporter: problemReporter)
    }

    for stringsdictFile in base.stringsdict {
        guard let translationStringsdictFile = translation.stringsdict.first(where: { $0.name == stringsdictFile.name })
        else {
            problemReporter.report(
                .error,
                path: stringsdictFile.name,
                lineNumber: 0,
                message: "\(stringsdictFile.name) missing from translation \(translation.name)")
            continue
        }
        validateStringsdict(base: stringsdictFile, translation: translationStringsdictFile)
    }
}
