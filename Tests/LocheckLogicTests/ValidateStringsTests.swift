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
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"tneserp\";",
                    path: "def",
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            baseLanguageName: "en",
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
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"%d %@\";",
                    path: "def",
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            baseLanguageName: "en",
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertFalse(problemReporter.hasError)
        XCTAssertEqual(
            problemReporter.problems.map(\.messageForXcode),
            [
                ":0: warning: Argument 1 in \'present %d %@\' has an implicit position. Use an explicit position for safety (%$1d). (string_has_implicit_position)",
                ":0: warning: Argument 2 in \'present %d %@\' has an implicit position. Use an explicit position for safety (%$2@). (string_has_implicit_position)",
                "def:0: warning: Argument 1 in translation of \'present %d %@\' (\'%d %@\') has an implicit position. Use an explicit position for safety (%$1d). (string_has_implicit_position)",
                "def:0: warning: Argument 2 in translation of \'present %d %@\' (\'%d %@\') has an implicit position. Use an explicit position for safety (%$2@). (string_has_implicit_position)",
            ])
    }

    func testInvalid_implicitOrderArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"present %d %@\";",
                    path: "abc",
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"%@ %d tneserp\";", // specifiers swapped
                    path: "def",
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            baseLanguageName: "en",
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertTrue(problemReporter.hasError)
        XCTAssertEqual(
            problemReporter.problems.map(\.messageForXcode),
            [
                ":0: warning: Argument 1 in \'present %d %@\' has an implicit position. Use an explicit position for safety (%$1d). (string_has_implicit_position)",
                ":0: warning: Argument 2 in \'present %d %@\' has an implicit position. Use an explicit position for safety (%$2@). (string_has_implicit_position)",
                "def:0: warning: Argument 1 in translation of \'present %d %@\' (\'%@ %d tneserp\') has an implicit position. Use an explicit position for safety (%$1@). (string_has_implicit_position)",
                "def:0: error: Specifier for argument 1 does not match (should be d, is @) (string_has_invalid_argument)",
                "def:0: warning: Argument 2 in translation of \'present %d %@\' (\'%@ %d tneserp\') has an implicit position. Use an explicit position for safety (%$2d). (string_has_implicit_position)",
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
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %1$d %2$@\" = \"tneserp %2$@ %1$d\";",
                    path: "def",
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            baseLanguageName: "en",
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
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
                LocalizedStringPair(
                    string: "\"missing\" = \"missing\";",
                    path: "abc",
                    line: 1,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"tneserp\";",
                    path: "def",
                    line: 0,
                    basePath: "",
                    baseLineFallback: 0)!,
            ],
            baseLanguageName: "en",
            translationLanguageName: "trnsltn",
            problemReporter: problemReporter)

        XCTAssertEqual(
            problemReporter.problems.map(\.messageForXcode), [
                "abc:1: warning: 'missing' is missing from trnsltn (key_missing_from_translation)",
            ])
    }
}
