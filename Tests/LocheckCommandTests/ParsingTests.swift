//
//  ParsingTests.swift
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

class ParsingTests: XCTestCase {
    func testArgumentParsing() {
        let problemReporter = ProblemReporter(log: false)
        let string = LocalizedString(
            string: """
            "%1$@ %2$d %@" = "%1$@ %2$d %@";
            """,
            file: FakeFile(path: "abc", nameExcludingExtension: "def"),
            line: 0)!
        XCTAssertEqual(
            string.baseArguments,
            [
                FormatArgument(specifier: "@", position: 1),
                FormatArgument(specifier: "d", position: 2),
                FormatArgument(specifier: "@", position: 3),
            ])
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testOmitArgument() {
        let problemReporter = ProblemReporter(log: false)
        let string = LocalizedString(
            string: """
            "A sync error occurred while creating column “%@” in project “%@”." = "Er is een synchronisatiefout opgetreden tijdens het maken van kolom “%@” in een project.";
            """,
            file: FakeFile(path: "abc", nameExcludingExtension: "def"),
            line: 0)!
        XCTAssertEqual(
            string.baseArguments,
            [FormatArgument(specifier: "@", position: 1), FormatArgument(specifier: "@", position: 2)])
        XCTAssertEqual(
            string.translationArguments,
            [FormatArgument(specifier: "@", position: 1)])
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testMixedImplicitAndExplicitOrder() {
        let problemReporter = ProblemReporter(log: false)
        let string = LocalizedString(
            string: """
            "A sync error occurred while processing %@'s request to join “%@”." = "“%@” 님의 “%2$@” 참가 요청을 처리하는 중 동기화 오류가 발생했습니다.";
            """,
            file: FakeFile(path: "abc", nameExcludingExtension: "def"),
            line: 0)!
        XCTAssertEqual(
            string.baseArguments,
            [FormatArgument(specifier: "@", position: 1), FormatArgument(specifier: "@", position: 2)])
        XCTAssertEqual(
            string.translationArguments,
            [FormatArgument(specifier: "@", position: 1), FormatArgument(specifier: "@", position: 2)])
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }
}
