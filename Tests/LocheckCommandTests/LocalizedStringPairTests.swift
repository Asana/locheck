//
//  LocalizedStringPairTests.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
@testable import LocheckLogic
import XCTest

class LocalizedStringPairTests: XCTestCase {
    func testArgumentParsing() {
        let problemReporter = ProblemReporter(log: false)
        let string = LocalizedStringPair(
            string: """
            "%1$@ %2$d %@" = "%1$@ %2$d %@";
            """,
            path: "abc",
            line: 0)!
        XCTAssertEqual(
            string.base.arguments,
            [
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: true),
                FormatArgument(specifier: "d", position: 2, isPositionExplicit: true),
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: false),
            ])
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testOmitArgument() {
        let problemReporter = ProblemReporter(log: false)
        let string = LocalizedStringPair(
            string: """
            "A sync error occurred while creating column “%@” in project “%@”." = "Er is een synchronisatiefout opgetreden tijdens het maken van kolom “%@” in een project.";
            """,
            path: "abc",
            line: 0)!
        XCTAssertEqual(
            string.base.arguments,
            [
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: false),
                FormatArgument(specifier: "@", position: 2, isPositionExplicit: false),
            ])
        XCTAssertEqual(
            string.translation.arguments,
            [FormatArgument(specifier: "@", position: 1, isPositionExplicit: false)])
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }

    func testMixedImplicitAndExplicitOrder() {
        let problemReporter = ProblemReporter(log: false)
        let string = LocalizedStringPair(
            string: """
            "A sync error occurred while processing %@'s request to join “%@”." = "“%@” 님의 “%2$@” 참가 요청을 처리하는 중 동기화 오류가 발생했습니다.";
            """,
            path: "abc",
            line: 0)!
        XCTAssertEqual(
            string.base.arguments,
            [
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: false),
                FormatArgument(specifier: "@", position: 2, isPositionExplicit: false),
            ])
        XCTAssertEqual(
            string.translation.arguments,
            [
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: false),
                FormatArgument(specifier: "@", position: 2, isPositionExplicit: true),
            ])
        XCTAssertTrue(problemReporter.problems.isEmpty)
    }
}
