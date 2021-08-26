//
//  StringsdictVariable.swift
//  
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

struct StringsdictRule: Equatable {
    let key: String
    let specType: String
    let valueType: String
    let alternatives: [String: LexedStringsdictString]
}

extension StringsdictRule {
    init?(key: String, node: XML.Element, path: String, problemReporter: ProblemReporter) {
        let reportError = { (message: String) -> Void in
            // lineNumber is zero because we don't have it from SwiftyXMLParser.
            problemReporter.report(.error, path: path, lineNumber: 0, message: message)
        }

        var maybeSpecType: String?
        var maybeValueType: String?
        var alternatives = [String: LexedStringsdictString]()

        for (valueKey, valueNode) in readPlistDict(root: node, path: path, problemReporter: problemReporter) {
            switch valueKey {
            case "NSStringFormatSpecTypeKey":
                maybeSpecType = valueNode.text
            case "NSStringFormatValueTypeKey":
                maybeValueType = valueNode.text
            default:
                alternatives[valueKey] = LexedStringsdictString(string: valueNode.text ?? "")
            }
        }

        if maybeSpecType == nil {
            reportError("Missing NSStringFormatSpecTypeKey in \(key)")
        }

        if maybeValueType == nil {
            reportError("Missing NSStringFormatValueTypeKey in \(key)")
        }

        if alternatives.isEmpty {
            reportError("No variables are defined in \(key)")
        }

        guard let specType = maybeSpecType, let valueType = maybeValueType, !alternatives.isEmpty else {
            return nil
        }

        self.key = key
        self.specType = specType
        self.valueType = valueType
        self.alternatives = alternatives
    }
}
