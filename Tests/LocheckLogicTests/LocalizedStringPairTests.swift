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
    func testSlashParsing() {
        let string = LocalizedStringPair(string: "//", path: "abc", line: 0)
        XCTAssertNil(string)

        let string2 = LocalizedStringPair(string: "////////////////////////", path: "abc", line: 0)
        XCTAssertNil(string2)
    }

    func testArgumentParsing() {
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
    }

    func testOmitArgument() {
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
    }

    func testMixedImplicitAndExplicitOrder() {
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
    }

    func testVariableSpacing() {
        // one space
        XCTAssertNotNil(LocalizedStringPair(string: #""Test key" = "Test value";"#, path: "abc", line: 0))
        // no spaces
        XCTAssertNotNil(LocalizedStringPair(string: #""Test key"="Test value";"#, path: "abc", line: 0))
        // mixed spaces
        XCTAssertNotNil(LocalizedStringPair(string: #""Test key"= "Test value";"#, path: "abc", line: 0))
        XCTAssertNotNil(LocalizedStringPair(string: #""Test key" ="Test value";"#, path: "abc", line: 0))
        // multiple spaces
        XCTAssertNotNil(LocalizedStringPair(string: #""Test key"  =  "Test value";"#, path: "abc", line: 0))
    }

    func testComments() {
        // no comment
        XCTAssertNotNil(LocalizedStringPair(string: #""Test key" = "Test value";"#, path: "abc", line: 0))
        // block comment after
        XCTAssertNotNil(LocalizedStringPair(
            string: #""Test key" = "Test value"; /* this is a comment */"#,
            path: "abc",
            line: 0))
        // multiple block comments after
        XCTAssertNotNil(LocalizedStringPair(
            string: #""Test key" = "Test value"; /* this is a comment */ /* this is another comment */"#,
            path: "abc",
            line: 0))
        // block comment before
        XCTAssertNotNil(LocalizedStringPair(
            string: #"/* this is a comment */ "Test key" = "Test value";"#,
            path: "abc",
            line: 0))
        // multiple block comment before
        XCTAssertNotNil(LocalizedStringPair(
            string: #"/* this is a comment */ /* this is also a comment */ "Test key" = "Test value";"#,
            path: "abc",
            line: 0))
        // single-line comment after
        XCTAssertNotNil(LocalizedStringPair(
            string: #""Test key" = "Test value"; // this is a comment"#,
            path: "abc",
            line: 0))
    }
}
