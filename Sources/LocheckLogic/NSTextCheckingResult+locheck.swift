//
//  NSTextCheckingResult+locheck.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Foundation

extension NSTextCheckingResult {
    /**
     Wraps boilerplate for getting group strings out of a regular expression match
     */
    func getGroupStrings(original: String) -> [String] {
        (0 ..< numberOfRanges).compactMap { i in
            let matchRange = range(at: i)
            if matchRange == NSRange(original.startIndex ..< original.endIndex, in: original) {
                return nil
            } else if let substringRange = Range(matchRange, in: original) {
                return String(original[substringRange])
            } else {
                return nil
            }
        }
    }
}
