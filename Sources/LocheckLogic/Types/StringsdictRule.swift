//
//  StringsdictRule.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

/**
 See `Stringsdict.swift` for a comment about what each type represents.
 */
struct StringsdictRule: Equatable {
    let key: String
    let line: Int
    let specType: String
    let valueType: String
    let alternatives: [String: LexedStringsdictString]
}

extension StringsdictRule {
    init?(key: String, node: XML.Element, path: String, problemReporter: ProblemReporter) {
        self.line = node.lineNumberStart

        let report = { (problem: Problem) -> Void in
            problemReporter.report(problem, path: path, lineNumber: node.lineNumberStart)
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
                guard let text = valueNode.text else {
                    return nil
                }
                alternatives[valueKey] = LexedStringsdictString(string: text)
            }
        }

        if maybeSpecType == nil {
            report(StringsdictEntryMissingFormatSpecTypeProblem(key: key))
        }

        if maybeValueType == nil {
            report(StringsdictEntryMissingFormatValueTypeProblem(key: key))
        }

        if alternatives.isEmpty {
            report(StringsdictEntryContainsNoVariablesProblem(key: key))
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
