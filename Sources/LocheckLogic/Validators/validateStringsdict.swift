//
//  stringsdict.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

public func validateStringsdict(
    base: File,
    translation: File,
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    guard
        let baseStringsdict = Stringsdict(file: base, problemReporter: problemReporter),
        let translationStringsdict = Stringsdict(file: translation, problemReporter: problemReporter) else {
        return
    }
    print(baseStringsdict)
    print(translationStringsdict)
}
