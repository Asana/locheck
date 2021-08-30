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
            ])

        let problemReporter = ProblemReporter(log: false)
        entry.validateRuleVariables(path: "en.stringsdict", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems.map(\.message), [
            "Variable xyz does not exist in 'abc' but is used in the format key",
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
            ])

        let problemReporter = ProblemReporter(log: false)
        entry.validateRuleVariables(path: "en.stringsdict", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems.map(\.message), [
            "Variable xyz does not exist in 'abc' but is used in 'def'.other",
        ])
    }

    func testRuleExpansion_baseCase() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "abc"),
            rules: [:])

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
            ])

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
            ])

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
                    key: "n",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "o"),
                        "other": LexedStringsdictString(string: "p"),
                    ]),
            ])

        XCTAssertEqual(entry.allPermutations, ["b o", "b p", "c o", "c p"])
    }

    func testGetCanonicalArgumentList_logsNoErrorsForValidEntry() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "%1$d %#@level1@"),
            rules: [
                "level1": StringsdictRule(
                    key: "level1",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "%2$d %#@level2@"),
                        "other": LexedStringsdictString(string: "%2$d other %#@level2@"),
                    ]),
                "level2": StringsdictRule(
                    key: "level2",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "%3$d"),
                        "other": LexedStringsdictString(string: "%3$d other"),
                    ]),
            ])
        let problemReporter = ProblemReporter(log: false)
        let argList = entry.getCanonicalArgumentList(path: "abc", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems, [])
        XCTAssertEqual(
            argList,
            [
                FormatArgument(specifier: "d", position: 1, isPositionExplicit: true),
                FormatArgument(specifier: "d", position: 2, isPositionExplicit: true),
                FormatArgument(specifier: "d", position: 3, isPositionExplicit: true),
            ])
    }

    func testGetCanonicalArgumentList_logsErrorForSpecifierMismatch() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "%1$d %#@level1@"),
            rules: [
                "level1": StringsdictRule(
                    key: "level1",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "%2$d %#@level2@"),
                        "other": LexedStringsdictString(string: "%2$@ other %#@level2@"), // @ instead of d
                    ]),
                "level2": StringsdictRule(
                    key: "level2",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "%3$d"),
                        "other": LexedStringsdictString(string: "%3$d other"),
                    ]),
            ])
        let problemReporter = ProblemReporter(log: false)
        let argList = entry.getCanonicalArgumentList(path: "abc", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems.map(\.message), [
            "Two permutations of 'abc' contain different format specifiers at position 2. '%1$d %2$@ other %3$d' uses '@', and '%1$d %2$d %3$d' uses 'd'.",
            "Two permutations of 'abc' contain different format specifiers at position 2. '%1$d %2$@ other %3$d' uses '@', and '%1$d %2$d %3$d other' uses 'd'.",
        ])
        XCTAssertEqual(
            argList,
            [
                FormatArgument(specifier: "d", position: 1, isPositionExplicit: true),
                FormatArgument(specifier: "@", position: 2, isPositionExplicit: true),
                // %@ wins because its string sorts first
                FormatArgument(specifier: "d", position: 3, isPositionExplicit: true),
            ])
    }

    func testGetCanonicalArgumentList_logsErrorForUnusedArgument() {
        let entry = StringsdictEntry(
            key: "abc",
            formatKey: LexedStringsdictString(string: "%1$d %#@level1@"),
            rules: [
                "level1": StringsdictRule(
                    key: "level1",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "%#@level2@"), // $2 not present
                        "other": LexedStringsdictString(string: "other %#@level2@"), // $2 not present
                    ]),
                "level2": StringsdictRule(
                    key: "level2",
                    specType: "plural",
                    valueType: "d",
                    alternatives: [
                        "one": LexedStringsdictString(string: "%3$d"),
                        "other": LexedStringsdictString(string: "%3$d other"),
                    ]),
            ])
        let problemReporter = ProblemReporter(log: false)
        let argList = entry.getCanonicalArgumentList(path: "abc", problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems.map(\.message), [
            "No permutation of 'abc' use argument(s) at position 2",
        ])
        XCTAssertEqual(
            argList,
            [
                FormatArgument(specifier: "d", position: 1, isPositionExplicit: true),
                nil,
                FormatArgument(specifier: "d", position: 3, isPositionExplicit: true),
            ])
    }
}
