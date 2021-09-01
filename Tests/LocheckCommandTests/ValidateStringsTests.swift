//
//  ValidateStringsTests.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
@testable import LocheckLogic
import XCTest

class ValidateStringsTests: XCTestCase {
    func testValid_noArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"present\";",
                    path: "abc",
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"tneserp\";",
                    path: "def",
                    line: 0)!,
            ],
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertFalse(problemReporter.hasError)
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testValid_implicitOrderArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"present %d %@\";",
                    path: "abc",
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"%d %@\";",
                    path: "def",
                    line: 0)!,
            ],
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertFalse(problemReporter.hasError)
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testInvalid_implicitOrderArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"present %d %@\";",
                    path: "abc",
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"%@ %d tneserp\";", // specifiers swapped
                    path: "def",
                    line: 0)!,
            ],
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertTrue(problemReporter.hasError)
        XCTAssertEqual(
            problemReporter.problems.map(\.messageForXcode),
            [
                "def:0: error: Specifier for argument 1 does not match (should be d, is @) (string_has_invalid_argument)",
                "def:0: error: Specifier for argument 2 does not match (should be @, is d) (string_has_invalid_argument)",
            ])
    }

    func testValid_explicitOrderArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present %1$d %2$@\" = \"present %1$d %2$@\";",
                    path: "abc",
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %1$d %2$@\" = \"tneserp %2$@ %1$d\";",
                    path: "def",
                    line: 0)!,
            ],
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertFalse(problemReporter.hasError)
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testMissing() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"present\";",
                    path: "abc",
                    line: 0)!,
                LocalizedStringPair(
                    string: "\"missing\" = \"missing\";",
                    path: "abc",
                    line: 1)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"tneserp\";",
                    path: "def",
                    line: 0)!,
            ],
            translationLanguageName: "trnsltn",
            problemReporter: problemReporter)

        XCTAssertEqual(
            problemReporter.problems.map(\.messageForXcode), [
                "abc:1: warning: 'missing' is missing from trnsltn (key_missing_from_translation)",
            ])
    }
}
