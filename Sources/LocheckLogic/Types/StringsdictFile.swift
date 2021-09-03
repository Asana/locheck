//
//  Stringsdict.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Files
import Foundation
import SwiftyXMLParser

/**
 Each stringsdict file contains an unsorted list of entry key-value pairs. The key is what appears in your
 source code (`NSLocalizedString("That's %d cool motorcycle(s)!")`) and the value is what we call an _entry_.

 An entry has a _format key_ () whose value is a string that contains variables.
 Variables look like `%#@name_of_variable@`. Each variable may be expanded into one of a list of _alternatives_`
 defined by _rules_.

 Here is a complete example of all the parts of an entry:

 ```
 "That's %d cool motorcycle(s)!"                            // This is the "entry key"
     NSStringLocalizedFormatKey: "That's %#@motorcycles@!"  // the format key with a "motorcycles" variable
    motorcycles:                                            // the 'rule'
        one: "a cool motorcycle"                            // one 'alternative'
        other: "%d cool motorcycles"                        // another 'alternative'
 ```
 */
public struct StringsdictFile: Equatable {
    public let path: String
    public let entries: [StringsdictEntry]

    init(path: String, entries: [StringsdictEntry]) {
        self.path = path
        self.entries = entries
    }

    public init?(path: String, problemReporter: ProblemReporter) {
        self.path = path
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
