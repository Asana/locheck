//
//  Stringsdict.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Files
import Foundation
import SwiftyXMLParser

private func parseXML(file: File, problemReporter: ProblemReporter) -> XML.Accessor? {
    do {
        return XML.parse(try file.read())
    } catch {
        problemReporter.report(
            XMLErrorProblem(message: error.localizedDescription),
            path: file.path, lineNumber: 0)
        return nil
    }
}

struct Stringsdict: Equatable {
    let entries: [StringsdictEntry]

    init(entries: [StringsdictEntry]) {
        self.entries = entries
    }

    init?(path: String, problemReporter: ProblemReporter) {
        guard let xml = parseXML(file: try! File(path: path), problemReporter: problemReporter) else {
            return nil
        }
        guard let dict = xml.all![0].childElements.first?.childElements.first else {
            problemReporter.report(
                XMLSchemaProblem(message: "XML schema error: no dict at top level"),
                path: path,
                lineNumber: 0)
            return nil
        }

        var entries = [StringsdictEntry]()

        for (dictKey, valueNode) in readPlistDict(root: dict, path: path, problemReporter: problemReporter) {
            guard let entry = StringsdictEntry(
                key: dictKey,
                node: valueNode,
                path: path,
                problemReporter: problemReporter) else {
                return nil
            }
            entries.append(entry)
        }

        self.entries = entries
    }
}
