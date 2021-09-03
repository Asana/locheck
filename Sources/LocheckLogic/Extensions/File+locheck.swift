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
        } catch is FilesError<Files.ReadErrorReason> {
            // try UTF-16 below
        } catch {
            problemReporter.report(
                SwiftError(description: error.localizedDescription),
                path: path,
                lineNumber: 0)
            return nil
        }

        do {
            return try readAsString(encodedAs: .utf16)
                .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .map { String($0) }
        } catch is FilesError<Files.ReadErrorReason> {
            problemReporter.report(
                SwiftError(description: "File is not encoded as UTF-8 or UTF-16"),
                path: path,
                lineNumber: 0)
            return nil
        } catch {
            problemReporter.report(
                SwiftError(description: error.localizedDescription),
                path: path,
                lineNumber: 0)
            return nil
        }
    }
}
