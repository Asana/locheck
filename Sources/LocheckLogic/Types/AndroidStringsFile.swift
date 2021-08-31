//
//  File.swift
//
//
//  Created by Steve Landey on 8/31/21.
//
import Files
import Foundation
import SwiftyXMLParser

struct AndroidPlural: Equatable {
    let key: String
    let values: [String: FormatString]
}

struct AndroidString: Equatable {
    let key: String
    let value: FormatString
}

struct AndroidStringsFile: Equatable {
    let strings: [String: AndroidString]
    let plurals: [String: AndroidPlural]
}

extension AndroidStringsFile {
    init?(path: String, problemReporter: ProblemReporter) {
        guard let xml = parseXML(file: try! File(path: path), problemReporter: problemReporter) else {
            return nil
        }
        guard let list = xml["resources"].element?.childElements else {
            problemReporter.report(
                XMLSchemaProblem(message: "XML schema error: no dict at top level"),
                path: path,
                lineNumber: nil)
            return nil
        }

        var strings = [String: AndroidString]()
        var plurals = [String: AndroidPlural]()
        for (i, element) in list.enumerated() {
            guard let key = element.attributes["name"] else {
                problemReporter.report(
                    XMLSchemaProblem(message: "Item \(i + 1) is missing 'name' attribute"),
                    path: path,
                    lineNumber: nil)
                continue
            }
            guard strings[key] == nil else {
                problemReporter.report(DuplicateEntries(context: nil, name: key), path: path, lineNumber: nil)
                continue
            }
            switch element.name {
            case "string":
                strings[key] = AndroidString(
                    key: key,
                    value: FormatString(string: element.text ?? "", path: path, line: nil))
            case "plurals":
                var values = [String: FormatString]()
                for child in element.childElements {
                    guard child.name == "item" else {
                        problemReporter.report(
                            XMLSchemaProblem(message: "Item \(i + 1) has a malformed child (not an 'item')"),
                            path: path,
                            lineNumber: nil)
                        continue
                    }
                    guard let childKey = child.attributes["quantity"] else {
                        problemReporter.report(
                            XMLSchemaProblem(message: "A child of item \(i + 1) is missing 'quantity' attribute"),
                            path: path,
                            lineNumber: nil)
                        continue
                    }
                    guard values[childKey] == nil else {
                        problemReporter.report(
                            DuplicateEntries(context: key, name: childKey),
                            path: path,
                            lineNumber: nil)
                        continue
                    }
                    values[childKey] = FormatString(string: child.text ?? "", path: path, line: nil)
                }
                plurals[key] = AndroidPlural(key: key, values: values)
            default:
                problemReporter.report(
                    XMLSchemaProblem(message: "Item \(i + 1) has unknown type: '\(element.name)'"),
                    path: path,
                    lineNumber: nil)
            }
        }

        self.strings = strings
        self.plurals = plurals
    }
}
