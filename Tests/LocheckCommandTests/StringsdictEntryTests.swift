//
//  StringsdictEntryTests.swift
//
//
//  Created by Steve Landey on 8/26/21.
//

import Files
@testable import LocheckLogic
import XCTest

class StringsdictEntryTests: XCTestCase {
    func testMissingVariableInRoot() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "%#@def@ %#@xyz@"), // def exists, xyz doesn't
            rules: [
                "def": StringsdictRule(
                    key: "def",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "other": LexedStringsdictString(string: "DEF"),
                    ]),
            ],
            orderedRuleKeys: ["def"])

        let problemReporter = ProblemReporter(log: false)
        entry.validateRuleVariables(path: "en.stringsdict", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems, [
            ProblemReporter.Problem(
                path: "en.stringsdict",
                lineNumber: 0,
                message: "Variable xyz does not exist in 'abc' but is used in the format key",
                severity: .error),
        ])
    }

    func testMissingVariableInRule() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "%#@def@"),
            rules: [
                "def": StringsdictRule(
                    key: "def",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "other": LexedStringsdictString(string: "%#@xyz@"),
                    ]),
            ],
            orderedRuleKeys: ["def"])

        let problemReporter = ProblemReporter(log: false)
        entry.validateRuleVariables(path: "en.stringsdict", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems, [
            ProblemReporter.Problem(
                path: "en.stringsdict",
                lineNumber: 0,
                message: "Variable xyz does not exist in 'abc' but is used in 'def'.other",
                severity: .error),
        ])
    }
}
