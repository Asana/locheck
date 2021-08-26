//
//  StringsdictEntry.swift
//  
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

struct StringsdictEntry: Equatable {
    let key: String
    let formatKey: String
    let rules: [String: StringsdictRule] // derived from XML
    let orderedRuleKeys: [String] // derived from formatKey

    var orderedRules: [StringsdictRule] {
        orderedRuleKeys.map { rules[$0]! }
    }
}

extension StringsdictEntry {
    init?(key: String, node: XML.Element, path: String, problemReporter: ProblemReporter) {
        let reportError = { (message: String) -> Void in
            // lineNumber is zero because we don't have it from SwiftyXMLParser.
            problemReporter.report(.error, path: path, lineNumber: 0, message: message)
        }

        var maybeFormatKey: String?
        var rules = [String: StringsdictRule]()
        var maybeOrderedRuleKeys: [String]?

        for (valueKey, valueNode) in readPlistDict(
            root: node,
            path: path,
            problemReporter: problemReporter) {
            guard let valueText = valueNode.text else {
                reportError("No value for key \(key).\(valueKey)")
                return nil
            }
            switch valueKey {
            case "NSStringLocalizedFormatKey":
                guard valueNode.name == "string" else {
                    reportError("Unexpected value for key \(valueKey): \(valueNode.name)")
                    return nil
                }
                maybeFormatKey = valueText
                maybeOrderedRuleKeys = Expressions.stringsdictArgumentRegex
                    .lo_matches(in: valueText)
                    .compactMap { $0.lo_getGroup(in: valueText, named: "name") }
            default:
                guard let variable = StringsdictRule(key: valueKey, node: valueNode, path: path, problemReporter: problemReporter) else {
                    return nil
                }
                rules[valueKey] = variable
            }
        }

        if maybeFormatKey == nil {
            reportError("\(key) contains no value for NSStringLocalizedFormatKey")
        }
        if maybeOrderedRuleKeys == nil {
            reportError("\(key) contains no variables in its format key: \(maybeFormatKey ?? "<unknown>")")
        }
        var hasAllVariables = true
        for variableKey in (maybeOrderedRuleKeys ?? []) where rules[variableKey] == nil {
            reportError("Variable \(variableKey) is not defined in \(key)")
            hasAllVariables = false
        }

        guard let formatKey = maybeFormatKey, let orderedRuleKeys = maybeOrderedRuleKeys, hasAllVariables else {
            return nil
        }

        self.key = key
        self.formatKey = formatKey
        self.orderedRuleKeys = orderedRuleKeys
        self.rules = rules
    }
}
