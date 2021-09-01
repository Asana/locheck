//
//  parseAndValidateAndroidStringsTests.swift
//
//
//  Created by Steve Landey on 9/1/21.
//

import Files
import Foundation
@testable import LocheckLogic
import XCTest

class ParseAndValidateAndroidStringsTests: XCTestCase {
    fileprivate let packageRootPath = URL(fileURLWithPath: #file)
        .pathComponents
        .prefix(while: { $0 != "Tests" })
        .joined(separator: "/")
        .dropFirst()

    func testParseAndValidateDemoFiles() {
        let problemReporter = ProblemReporter(log: false)
        parseAndValidateAndroidStrings(
            base: try! File(path: "\(packageRootPath)/Examples/strings-base.xml"),
            translation: try! File(path: "\(packageRootPath)/Examples/strings-translation.xml"),
            translationLanguageName: "demo",
            problemReporter: problemReporter)

        XCTAssertEqual(problemReporter.problems.count, 5)
        let problems = problemReporter.problems.map(\.problem)
        CastAndAssertEqual(problems[0], KeyMissingFromTranslation(key: "missing_from_translation", language: "demo"))
        CastAndAssertEqual(problems[1], KeyMissingFromBase(key: "missing_from_base"))
    }
}
