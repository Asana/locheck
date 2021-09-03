//
//  File+locheck.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
import Foundation

extension File {
    func lo_getLines(problemReporter: ProblemReporter) -> [String]? {
        do {
            return try readAsString()
                .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .map { String($0) }
        } catch {
            problemReporter.report(
                SwiftError(error: error),
                path: path,
                lineNumber: 0)
            return nil
        }
    }
}
