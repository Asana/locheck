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
public func validateLproj(primary: LprojFiles, secondary: LprojFiles, problemReporter: ProblemReporter) {
    for stringsFile in primary.strings {
        guard let secondaryStringsFile = secondary.strings.first(where: { $0.name == stringsFile.name }) else {
            problemReporter.report(
                .error,
                path: stringsFile.name,
                lineNumber: 0,
                message: "\(stringsFile.name) missing from translation \(secondary.name)")
            continue
        }
        parseAndValidateStrings(
            primary: stringsFile,
            secondary: secondaryStringsFile,
            secondaryLanguageName: secondary.name,
            problemReporter: problemReporter)
    }

    for stringsdictFile in primary.stringsdict {
        guard let secondaryStringsdictFile = secondary.stringsdict.first(where: { $0.name == stringsdictFile.name })
        else {
            problemReporter.report(
                .error,
                path: stringsdictFile.name,
                lineNumber: 0,
                message: "\(stringsdictFile.name) missing from translation \(secondary.name)")
            continue
        }
        validateStringsdict(primary: stringsdictFile, secondary: secondaryStringsdictFile)
    }
}
