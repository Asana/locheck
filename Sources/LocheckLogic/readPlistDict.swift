//
//  readPlistDict.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

func readPlistDict(
    root: XML.Element,
    path: String,
    problemReporter: ProblemReporter) -> [(String, XML.Element)] {
    guard root.name == "dict" else {
        problemReporter.report(
            XMLSchemaProblem(message: "Malformed plist; object isn't a dict"),
            path: path,
            lineNumber: nil)
        return []
    }
    var results = [(String, XML.Element)]()
    for i in stride(from: 0, to: root.childElements.count, by: 2) {
        guard let key = root.childElements[i].text else {
            problemReporter.report(
                XMLSchemaProblem(message: "Malformed plist; can't find next key in dict"),
                path: path,
                lineNumber: nil)
            return []
        }
        results.append((key, root.childElements[i + 1]))
    }
    return results
}
