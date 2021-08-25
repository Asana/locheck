//
//  ValidateStringsTests.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

@testable import LocheckLogic
import XCTest

private struct FakeFile: Filing {
    let path: String
    let nameExcludingExtension: String
}

class ValidateStringsTests: XCTestCase {
    func testValid_noArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"present\";",
                    file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"tneserp\";",
                    file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
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
                    file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"%d %@\";",
                    file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
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
                    file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %d %@\" = \"%@ %d tneserp\";", // specifiers swapped
                    file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
                    line: 0)!,
            ],
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertTrue(problemReporter.hasError)
        XCTAssertEqual(
            problemReporter.problems,
            [
                ProblemReporter.Problem(
                    path: "def",
                    lineNumber: 0,
                    message: "Specifier for argument 1 does not match (should be d, is @)",
                    severity: .error),
                ProblemReporter.Problem(
                    path: "def",
                    lineNumber: 0,
                    message: "Specifier for argument 2 does not match (should be @, is d)",
                    severity: .error),
            ])
    }

    func testValid_explicitOrderArgs() {
        let problemReporter = ProblemReporter(log: false)
        validateStrings(
            baseStrings: [
                LocalizedStringPair(
                    string: "\"present %1$d %2$@\" = \"present %1$d %2$@\";",
                    file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
                    line: 0)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present %1$d %2$@\" = \"tneserp %2$@ %1$d\";",
                    file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
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
                    file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
                    line: 0)!,
                LocalizedStringPair(
                    string: "\"missing\" = \"missing\";",
                    file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
                    line: 1)!,
            ],
            translationStrings: [
                LocalizedStringPair(
                    string: "\"present\" = \"tneserp\";",
                    file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
                    line: 0)!,
            ],
            translationLanguageName: "translation",
            problemReporter: problemReporter)

        XCTAssertEqual(
            problemReporter.problems, [
                ProblemReporter.Problem(
                    path: "abc", lineNumber: 1, message: "This string is missing from translation", severity: .warning),
            ])
    }
}
