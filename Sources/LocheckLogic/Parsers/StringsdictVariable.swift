//
//  File.swift
//  
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

struct StringsdictVariable: Equatable {
    let key: String
    let specType: String
    let valueType: String
    let values: [String: LocalizedString]
}

extension StringsdictVariable {
    init?(key: String, node: XML.Element, path: String, problemReporter: ProblemReporter) {
        let reportError = { (message: String) -> Void in
            problemReporter.report(.error, path: path, lineNumber: 0, message: message)
        }

        var maybeSpecType: String?
        var maybeValueType: String?
        var values = [String: LocalizedString]()

        for (valueKey, valueNode) in readPlistDict(root: node, path: path, problemReporter: problemReporter) {
            switch valueKey {
            case "NSStringFormatSpecTypeKey":
                maybeSpecType = valueNode.text
            case "NSStringFormatValueTypeKey":
                maybeValueType = valueNode.text
            default:
                values[valueKey] = LocalizedString(string: valueNode.text ?? "", path: path, line: 0)
            }
        }

        if maybeSpecType == nil {
            reportError("Missing NSStringFormatSpecTypeKey in \(key)")
        }

        if maybeValueType == nil {
            reportError("Missing NSStringFormatValueTypeKey in \(key)")
        }

        if values.isEmpty {
            reportError("No variables are defined in \(key)")
        }

        guard let specType = maybeSpecType, let valueType = maybeValueType, !values.isEmpty else {
            return nil
        }

        self.key = key
        self.specType = specType
        self.valueType = valueType
        self.values = values
    }
}
