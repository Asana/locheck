//
//  FormatStringTests.swift
//
//
//  Created by Steve Landey on 9/1/21.
//

import Foundation
@testable import LocheckLogic
import XCTest

class FormatStringTests: XCTestCase {
    func testImplicitPositionCounterIgnoresExplicitPositions() {
        let formatString = FormatString(string: "%2$@ %@", path: "", line: 0)
        XCTAssertEqual(
            formatString.arguments,
            [
                FormatArgument(specifier: "@", position: 2, isPositionExplicit: true),
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: false),
            ])
    }

    // MARK: - Escaped percent (%%) tests for Android

    func testAndroidEscapedPercentOnly() {
        // "%%" is an escaped percent sign, should have no format arguments
        let formatString = FormatString(string: "100%% complete", path: "", line: 0, platform: .android)
        XCTAssertEqual(formatString.arguments, [])
    }

    func testAndroidEscapedPercentFollowedBySpace() {
        // "%% back" should not match "% b" as a format specifier
        let formatString = FormatString(string: "[ICON] %s %% back", path: "", line: 0, platform: .android)
        XCTAssertEqual(
            formatString.arguments,
            [
                FormatArgument(specifier: "s", position: 1, isPositionExplicit: false),
            ])
    }

    func testAndroidEscapedPercentThenFormatSpecifier() {
        // "%%%s" should be "%%" (escaped percent) + "%s" (format specifier)
        let formatString = FormatString(string: "100%%%s", path: "", line: 0, platform: .android)
        XCTAssertEqual(
            formatString.arguments,
            [
                FormatArgument(specifier: "s", position: 1, isPositionExplicit: false),
            ])
    }

    func testAndroidMultipleEscapedPercents() {
        // "%%%%" should be two escaped percents, no format arguments
        let formatString = FormatString(string: "100%%%% done", path: "", line: 0, platform: .android)
        XCTAssertEqual(formatString.arguments, [])
    }

    func testAndroidUnescapedPercentBecomesSpecifier() {
        // If a translator mistakenly changes "%%" to "%" before a valid specifier character,
        // it becomes a format specifier. This test documents that behavior.
        // Base: "100%% discount" -> no arguments (escaped percent)
        let base = FormatString(string: "100%% discount", path: "", line: 0, platform: .android)
        XCTAssertEqual(base.arguments, [])

        // Translation with typo: "100%d discount" -> HAS an argument (unescaped, %d is a specifier)
        let translationWithTypo = FormatString(string: "100%d discount", path: "", line: 0, platform: .android)
        XCTAssertEqual(
            translationWithTypo.arguments,
            [
                FormatArgument(specifier: "d", position: 1, isPositionExplicit: false),
            ])
    }
}
