//
//  StringsdictRule.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

/**
 Each entry in stringsdict contains at least one rule, i.e. a variable interpolation. For example:

 ```
 "That's %d cool motorcycle(s)!"        // This is the "entry key"
     Format key: "That's %#@motorcycles@!"
     motorcycles:                       // this is the 'rule'
         one: "a cool motorcycle"       // this is one 'alternative'
         other: "%d cool motorcycles"   // this is another 'alternative
 ```
 */
struct StringsdictRule: Equatable {
    let key: String
    let specType: String
    let valueType: String
    let alternatives: [String: LexedStringsdictString]
}

extension StringsdictRule {
    init?(key: String, node: XML.Element, path: String, problemReporter: ProblemReporter) {
        let report = { (problem: Problem) -> Void in
            // lineNumber is zero because we don't have it from SwiftyXMLParser.
            problemReporter.report(problem, path: path, lineNumber: 0)
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
                    print("MISSING TEXT IN", valueKey)
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
