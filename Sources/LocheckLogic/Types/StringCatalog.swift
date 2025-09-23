//
//  StringCatalog.swift
//
//
//  Created by Uladzislau Birukou on 9/22/25.
//

import Foundation

/**
 Represents a string catalog (.xcstrings) file
 */
struct StringCatalog: Codable {
    let sourceLanguage: String
    let strings: [String: StringEntry]
    let version: String
}

/**
 Represents a string entry in a string catalog
 */
struct StringEntry: Codable {
    let extractionState: String?
    let localizations: [String: Localization]
    let comment: String?
}

/**
 Represents a localization for a specific language
 */
struct Localization: Codable {
    let stringUnit: StringUnit?
    let variations: Variations?
}

/**
 Represents a simple string unit
 */
struct StringUnit: Codable {
    let state: String
    let value: String
}

/**
 Represents variations (e.g., plural forms, device variations)
 */
struct Variations: Codable {
    let plural: [String: PluralVariation]?
    let device: [String: DeviceVariation]?
}

/**
 Represents a plural variation
 */
struct PluralVariation: Codable {
    let stringUnit: StringUnit
}

/**
 Represents a device-specific variation
 */
struct DeviceVariation: Codable {
    let stringUnit: StringUnit
}

extension StringCatalog {
    /**
     Initialize StringCatalog from file path
     */
    init?(path: String, problemReporter: ProblemReporter) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            self = try decoder.decode(StringCatalog.self, from: data)
        } catch {
            problemReporter.report(
                InvalidFile(details: "Failed to parse string catalog: \(error.localizedDescription)"),
                path: path,
                lineNumber: 0)
            return nil
        }
    }
}

extension StringEntry {
    /**
     Get all localized string pairs for validation
     */
    func getLocalizedStringPairs(
        key: String,
        basePath: String,
        sourceLanguage: String
    ) -> [LocalizedStringPair] {
        var pairs: [LocalizedStringPair] = []
        
        guard let sourceLocalization = localizations[sourceLanguage] else {
            return pairs
        }
        
        let sourceString = sourceLocalization.stringUnit?.value ?? key
        
        for (language, localization) in localizations {
            if language == sourceLanguage {
                continue // Skip source language for validation
            }
            
            if let stringUnit = localization.stringUnit {
                let pair = LocalizedStringPair(
                    key: key,
                    baseString: sourceString,
                    translationString: stringUnit.value,
                    path: basePath,
                    line: 1
                )
                pairs.append(pair)
            }
            
            if let variations = localization.variations {
                // Handle plural variations
                if let pluralForms = variations.plural {
                    // Get source plural form for comparison (use "other" as fallback)
                    let sourcePlurals = sourceLocalization.variations?.plural
                    let fallbackSource = sourcePlurals?["other"]?.stringUnit.value ?? sourceString
                    
                    for (pluralForm, pluralVariation) in pluralForms {
                        let sourceForPluralForm = sourcePlurals?[pluralForm]?.stringUnit.value ?? fallbackSource
                        let pair = LocalizedStringPair(
                            key: "\(key) (\(pluralForm))",
                            baseString: sourceForPluralForm,
                            translationString: pluralVariation.stringUnit.value,
                            path: basePath,
                            line: 1
                        )
                        pairs.append(pair)
                    }
                }
                
                // Handle device variations  
                if let deviceForms = variations.device {
                    for (deviceType, deviceVariation) in deviceForms {
                        let pair = LocalizedStringPair(
                            key: "\(key) (\(deviceType))",
                            baseString: sourceString,
                            translationString: deviceVariation.stringUnit.value,
                            path: basePath,
                            line: 1
                        )
                        pairs.append(pair)
                    }
                }
            }
        }
        
        return pairs
    }
}
