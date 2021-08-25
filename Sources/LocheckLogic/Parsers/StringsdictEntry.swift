//
//  StringsdictEntry.swift
//  
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

struct StringsdictEntry {
    let key: String
    let formatKey: String
    let variables: [String: StringsdictVariable] // derived from XML
    let orderedVariableKeys: [String] // derived from formatKey
}

extension StringsdictEntry {
    init?(key: String, node: XML.Element, file: Filing, problemReporter: ProblemReporter) {
        let reportError = { (message: String) -> Void in
            problemReporter.report(.error, path: file.path, lineNumber: 0, message: message)
        }

        var formatKey: String?
        var variables = [String: StringsdictVariable]()
        var orderedVariableKeys: [String]?

        for (valueKey, valueNode) in readPlistDict(
            root: node,
            path: file.path,
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
                formatKey = valueText
                orderedVariableKeys = Expressions.stringsdictArgumentRegex
                    .lo_matches(in: valueText)
                    .compactMap { $0.lo_getGroup(in: valueText, named: "name") }
            default:
                guard let variable = StringsdictVariable(key: valueKey, node: valueNode, file: file, problemReporter: problemReporter) else {
                    return nil
                }
                variables[valueKey] = variable
            }
        }

        if formatKey == nil {
            reportError("\(key) contains no value for NSStringLocalizedFormatKey")
        }
        if orderedVariableKeys == nil {
            reportError("\(key) contains no variables in its format key: \(formatKey ?? "<unknown>")")
        }
        var hasAllVariables = true
        for variableKey in (orderedVariableKeys ?? []) where variables[variableKey] == nil {
            reportError("Variable \(variableKey) is not defined in \(key)")
            hasAllVariables = false
        }

        guard let formatKey = formatKey, let orderedVariableKeys = orderedVariableKeys, hasAllVariables else {
            return nil
        }

        self.key = key
        self.formatKey = formatKey
        self.orderedVariableKeys = orderedVariableKeys
        self.variables = variables
    }
}
