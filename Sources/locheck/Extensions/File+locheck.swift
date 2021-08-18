//
//  File+locheck.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
import Foundation

extension File {
  var lines: [String] {
    try! readAsString().split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map { String($0) }
  }
}
