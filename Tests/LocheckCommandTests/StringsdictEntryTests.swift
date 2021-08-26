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

    func testRuleExpansion_baseCase() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "abc"),
            rules: [:],
            orderedRuleKeys: ["def"])

        XCTAssertEqual(entry.allPermutations, ["abc"])
    }

    func testRuleExpansion_oneLevel_oneAlternative() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "abc %#@def@"),
            rules: [
                "def": StringsdictRule(
                    key: "def",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "other": LexedStringsdictString(string: "xyz"),
                    ]),
            ],
            orderedRuleKeys: ["def"])

        XCTAssertEqual(entry.allPermutations, ["abc xyz"])
    }

    func testRuleExpansion_oneLevel_twoAlternatives() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "abc %#@def@"),
            rules: [
                "def": StringsdictRule(
                    key: "def",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "x"),
                        "other": LexedStringsdictString(string: "xyz"),
                    ]),
            ],
            orderedRuleKeys: ["def"])

        XCTAssertEqual(entry.allPermutations, ["abc x", "abc xyz"])
    }

    func testRuleExpansion_twoLevels_fourAlternatives() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "%#@a@ %#@n@"),
            rules: [
                "a": StringsdictRule(
                    key: "a",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "b"),
                        "other": LexedStringsdictString(string: "c"),
                    ]),
                "n": StringsdictRule(
                    key: "a",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "o"),
                        "other": LexedStringsdictString(string: "p"),
                    ]),
            ],
            orderedRuleKeys: ["def"])

        XCTAssertEqual(entry.allPermutations, ["b o", "b p", "c o", "c p"])
    }
}
