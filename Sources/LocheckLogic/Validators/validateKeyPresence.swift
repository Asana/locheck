//
//  validateKeyPresence.swift
//  
//
//  Created by Steve Landey on 9/1/21.
//

import Foundation

func validateKeyPresence(
    basePath: String,
    baseKeys: Set<String>,
    baseLineNumberMap: [String: Int],
    translationPath: String,
    translationKeys: Set<String>,
    translationLineNumberMap: [String: Int],
    translationLanguageName: String,
    problemReporter: ProblemReporter) {
    for key in baseKeys.sorted() {
        if !translationKeys.contains(key) {
            problemReporter.report(
                KeyMissingFromTranslation(key: key, language: translationLanguageName),
                path: basePath,
                lineNumber: baseLineNumberMap[key])
        }
    }

    for key in translationKeys.sorted() {
        if !baseKeys.contains(key) {
            problemReporter.report(
                KeyMissingFromBase(key: key),
                path: translationPath,
                lineNumber: translationLineNumberMap[key])
        }
    }
}
