//
//  LexedStringsdictString.swift
//
//
//  Created by Steve Landey on 8/26/21.
//

import Foundation

struct LexedStringsdictString: Equatable {
    enum Part: Equatable {
        case constant(String)
        case variable(String)
    }

    let string: String
    let parts: [Part]

    var variables: [String] {
        parts.compactMap {
            switch $0 {
            case .constant: return nil
            case .variable(let name): return name
            }
        }
    }
}

extension LexedStringsdictString {
    init(string: String) {
        self.string = string

        let matches = Expressions.stringsdictArgumentRegex.lo_matches(in: string)

        guard !matches.isEmpty else {
            self.parts = [.constant(string)]
            return
        }

        var parts = [Part]()

        var lastMatchEnd = string.startIndex

        for match in matches where match.range.location != NSNotFound {
            guard let range = Range(match.range, in: string) else { continue }
            if lastMatchEnd < range.lowerBound {
                parts.append(.constant(String(string[lastMatchEnd ..< range.lowerBound])))
            }
            lastMatchEnd = range.upperBound
            guard let name = match.lo_getGroup(in: string, named: "name") else {
                continue
            }
            parts.append(.variable(name))
        }

        // If there are no variables or the last variable ends before the end of the string,
        // add the remainder of the string as a constant.
        if lastMatchEnd < string.endIndex {
            parts.append(.constant(String(string[lastMatchEnd ..< string.endIndex])))
        }

        self.parts = parts
    }
}
