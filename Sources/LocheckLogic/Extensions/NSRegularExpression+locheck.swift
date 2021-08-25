//
//  NSRegularExpression+locheck.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation

extension NSRegularExpression {
    func lo_matches(in string: String) -> [NSTextCheckingResult] {
        matches(in: string, options: [], range: string.lo_wholeRange)
    }
}
