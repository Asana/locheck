//
//  String+locheck.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation

extension String {
    var lo_wholeRange: NSRange {
        NSRange(startIndex ..< endIndex, in: self)
    }
}
