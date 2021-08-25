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
    func lo_getGroup(in string: String, named name: String) -> String? {
        let matchRange = range(withName: name)
        guard
            matchRange.location != NSNotFound,
            let substringRange = Range(matchRange, in: string) else {
            return nil
        }
        return String(string[substringRange])
    }
}
