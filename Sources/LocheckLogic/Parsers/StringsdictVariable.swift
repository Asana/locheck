//
//  File.swift
//  
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

struct StringsdictVariable {
    let key: String
    let specType: String
    let valueType: String
    let values: [String: LocalizedString]
}

extension StringsdictVariable {
    init?(key: String, node: XML.Element, file: Filing, problemReporter: ProblemReporter) {
        let reportError = { (message: String) -> Void in
            problemReporter.report(.error, path: file.path, lineNumber: 0, message: message)
        }

        var specType: String?
        var valueType: String?
        var values = [String: LocalizedString]()

        for (valueKey, valueNode) in readPlistDict(root: node, path: file.path, problemReporter: problemReporter) {
            switch valueKey {
            case "NSStringFormatSpecTypeKey":
                specType = valueNode.text
            case "NSStringFormatValueTypeKey":
                valueType = valueNode.text
            default:
                values[valueKey] = LocalizedString(string: valueNode.text ?? "", file: file, line: 0)
            }
        }

        if specType == nil {
            reportError("Missing NSStringFormatSpecTypeKey in \(key)")
        }

        if valueType == nil {
            reportError("Missing NSStringFormatValueTypeKey in \(key)")
        }

        if values.isEmpty {
            reportError("No variables are defined in \(key)")
        }

        guard let specType = specType, let valueType = valueType, !values.isEmpty else {
            return nil
        }

        self.key = key
        self.specType = specType
        self.valueType = valueType
        self.values = values
    }
}
