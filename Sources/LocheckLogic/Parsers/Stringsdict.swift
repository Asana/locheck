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
            .error,
            path: file.path,
            lineNumber: 0,
            message: "XML error: \(error.localizedDescription)")
        return nil
    }
}

struct Stringsdict {
    let entries: [StringsdictEntry]

    init(entries: [StringsdictEntry]) {
        self.entries = entries
    }

    init?(file: File, problemReporter: ProblemReporter) {
        guard let xml = parseXML(file: file, problemReporter: problemReporter) else {
            return nil
        }
        guard let dict = xml.all![0].childElements.first?.childElements.first else {
            problemReporter.report(
                .error,
                path: file.path,
                lineNumber: 0,
                message: "Invalid schema, can't find dict")
            return nil
        }

        var entries = [StringsdictEntry]()

        for (dictKey, valueNode) in readPlistDict(root: dict, path: file.path, problemReporter: problemReporter) {
            guard let entry = StringsdictEntry(
                key: dictKey,
                node: valueNode,
                file: file,
                problemReporter: problemReporter) else {
                return nil
            }
            entries.append(entry)
        }

        self.entries = entries

        for entry in entries {
            print("=====")
            print(entry)
        }
    }
}
