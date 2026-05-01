//
//  parseAndValidateStringCatalog.swift
//
//
//  Created by Uladzislau Birukou on 9/22/25.
//

import Files
import Foundation

/**
 Parse and validate a string catalog (.xcstrings) file
 */
public func parseAndValidateStringCatalog(
    stringCatalogFile: File,
    problemReporter: ProblemReporter) {
    
    guard let stringCatalog = StringCatalog(path: stringCatalogFile.path, problemReporter: problemReporter) else {
        return
    }
    
    var allPairs: [LocalizedStringPair] = []
    
    // Extract all localized string pairs from the catalog
    for (key, entry) in stringCatalog.strings {
        let pairs = entry.getLocalizedStringPairs(
            key: key,
            basePath: stringCatalogFile.path,
            sourceLanguage: stringCatalog.sourceLanguage
        )
        allPairs.append(contentsOf: pairs)
    }
    
    // Group by language for validation
    let pairsByLanguage = Dictionary(grouping: allPairs) { pair in
        // Extract language from validation context - we need to infer this from the translation
        // For now, we'll validate all pairs together as they already contain base/translation comparison
        return "all"
    }
    
    // Validate each language group
    for (_, pairs) in pairsByLanguage {
        validateStringCatalogPairs(
            pairs: pairs,
            sourceLanguage: stringCatalog.sourceLanguage,
            problemReporter: problemReporter
        )
    }
    
    // Additional string catalog specific validations
    validateStringCatalogStructure(stringCatalog: stringCatalog, problemReporter: problemReporter)
}

/**
 Validate string pairs from a string catalog
 */
private func validateStringCatalogPairs(
    pairs: [LocalizedStringPair],
    sourceLanguage: String,
    problemReporter: ProblemReporter) {
    
    for pair in pairs {
        // Check for format argument consistency
        let baseArgumentPositions = Set(pair.base.arguments.map(\.position))
        let translationArgumentPositions = Set(pair.translation.arguments.map(\.position))

        let missingArgumentPositions = baseArgumentPositions.subtracting(translationArgumentPositions)
        let extraArgumentPositions = translationArgumentPositions.subtracting(baseArgumentPositions)
        let hasDuplicates = translationArgumentPositions.count != pair.translation.arguments.count

        if !missingArgumentPositions.isEmpty {
            let args = missingArgumentPositions.sorted().map { String($0) }
            problemReporter.report(
                StringHasMissingArguments(
                    key: pair.key,
                    language: "translation", // We don't track specific language in this context
                    args: args,
                    base: pair.base.string,
                    translation: pair.translation.string),
                path: pair.path,
                lineNumber: pair.line)
        }

        if !extraArgumentPositions.isEmpty {
            let args = extraArgumentPositions.sorted().map { String($0) }
            problemReporter.report(
                StringHasExtraArguments(
                    key: pair.key,
                    language: "translation",
                    args: args,
                    base: pair.base.string,
                    translation: pair.translation.string),
                path: pair.path,
                lineNumber: pair.line)
        }

        if hasDuplicates {
            problemReporter.report(
                StringHasDuplicateArguments(
                    key: pair.key,
                    language: "translation",
                    base: pair.base.string,
                    translation: pair.translation.string),
                path: pair.path,
                lineNumber: pair.line)
        }

        // Check argument specifier consistency
        let baseArgs = pair.base.arguments.sorted(by: { $0.position < $1.position })
        for arg in pair.translation.arguments {
            guard let baseArg = baseArgs.first(where: { $0.position == arg.position }) else {
                continue // we already logged an error for this above
            }
            if arg.specifier != baseArg.specifier {
                problemReporter.report(
                    StringHasInvalidArgument(
                        key: pair.key,
                        language: "translation",
                        argPosition: arg.position,
                        baseArgSpecifier: baseArg.specifier,
                        argSpecifier: arg.specifier,
                        base: pair.base.string,
                        translation: pair.translation.string),
                    path: pair.path,
                    lineNumber: pair.line)
            }
        }
    }
}

/**
 Validate string catalog structure and consistency
 */
private func validateStringCatalogStructure(
    stringCatalog: StringCatalog,
    problemReporter: ProblemReporter) {
    
    let sourceLanguage = stringCatalog.sourceLanguage
    
    // Check that source language exists in all entries
    for (key, entry) in stringCatalog.strings {
        if entry.localizations?[sourceLanguage] == nil {
            problemReporter.report(
                KeyMissingFromTranslation(
                    key: key,
                    language: sourceLanguage),
                path: "StringCatalog",
                lineNumber: 1)
        }
        
        // Check for incomplete translations
        let sourceLocalization = entry.localizations?[sourceLanguage]
        for (language, localization) in entry.localizations ?? [:] {
            if language == sourceLanguage {
                continue
            }
            
            // Check if translation is marked as needs work
            if let stringUnit = localization.stringUnit,
               stringUnit.state == "needs_work" {
                problemReporter.report(
                    TranslationNeedsWork(key: key, language: language),
                    path: "StringCatalog",
                    lineNumber: 1)
            }
            
            // Check plural consistency
            if let sourcePlurals = sourceLocalization?.variations?.plural,
               let translationPlurals = localization.variations?.plural {
                
                // Ensure critical plural forms are present
                let requiredForms = ["one", "other"]
                for form in requiredForms {
                    if sourcePlurals[form] != nil && translationPlurals[form] == nil {
                        problemReporter.report(
                            MissingPluralForm(key: key, language: language, form: form),
                            path: "StringCatalog",
                            lineNumber: 1)
                    }
                }
            }
        }
    }
}
