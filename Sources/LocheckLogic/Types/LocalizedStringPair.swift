//
//  LocalizedStringPair.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
import Foundation

/**
 Represents a line from a `.strings` file, like this:

 ```
 "base string with an argument %@" = "translated string with an argument %@";
 ```
 */
struct LocalizedStringPair: Equatable {
    let key: String
    let string: String
    let base: FormatString
    let translation: FormatString
    let path: String
    let line: Int?
}

extension LocalizedStringPair {
    init?(
        string: String,
        path: String,
        line: Int?,
        baseStringMap: [String: FormatString]? = nil) { // only pass for translation strings
        guard
            let match = Expressions.stringPairRegex.lo_matches(in: string).first,
            let keySequence = match.lo_getGroup(in: string, named: "key")?.dropFirst().dropLast(),
            let valueSequence = match.lo_getGroup(in: string, named: "value")?.dropFirst().dropLast() else {
            return nil
        }
        let key = String(keySequence)
        self.key = key
        self.string = string
        self.path = path
        self.line = line

        // If the base string has its own translation, use that as the key. Sometimes developers omit format specifiers
        // from keys if they provide their own translation in their base language .strings file.
        if let base = baseStringMap?[key] {
            self.base = base
        } else {
            base = FormatString(string: key, path: path, line: line)
        }
        translation = FormatString(string: String(valueSequence), path: path, line: line)
    }
}
