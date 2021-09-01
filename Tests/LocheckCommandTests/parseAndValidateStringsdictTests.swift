//
//  parseAndValidateStringsdictTests.swift
//
//
//  Created by Steve Landey on 8/30/21.
//

import Files
import Foundation
@testable import LocheckLogic
import XCTest

class ParseAndValidateStringsdictTests: XCTestCase {
    fileprivate let packageRootPath = URL(fileURLWithPath: #file)
        .pathComponents
        .prefix(while: { $0 != "Tests" })
        .joined(separator: "/")
        .dropFirst()

    func testParseAndValidateDemoFiles() {
        let problemReporter = ProblemReporter(log: false)
        parseAndValidateStringsdict(
            base: try! File(path: "\(packageRootPath)/Examples/Demo_Base.stringsdict"),
            translation: try! File(path: "\(packageRootPath)/Examples/Demo_Translation.stringsdict"),
            translationLanguageName: "Demo_Translation",
            problemReporter: problemReporter)
        XCTAssertEqual(problemReporter.problems.count, 8)
        XCTAssertEqual(
            problemReporter.problems[0].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Base.stringsdict:22: warning: '%d/%d Completed' is missing from Demo_Translation (key_missing_from_translation)")
        XCTAssertEqual(
            problemReporter.problems[1].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Base.stringsdict:63: warning: 'missing from translation' is missing from Demo_Translation (key_missing_from_translation)")
        XCTAssertEqual(
            problemReporter.problems[2].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Translation.stringsdict:22: warning: 'missing from base' is missing from the base translation (key_missing_from_base)")
        XCTAssertEqual(
            problemReporter.problems[3].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Translation.stringsdict:6: ignored: Argument 2 in permutation '%2$lu jours toutes les %d semaines of 'Every %d week(s) on %lu days' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)")
        XCTAssertEqual(
            problemReporter.problems[4].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Translation.stringsdict:6: error: Two permutations of 'Every %d week(s) on %lu days' contain different format specifiers at position 2. '%2$lu jours toutes les %d semaines' uses 'lu', and '%2$lu jours toutes les %d semaines' uses 'd'. (stringsdict_entry_permutations_have_conflicting_specifiers)")
        XCTAssertEqual(
            problemReporter.problems[5].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Translation.stringsdict:6: warning: No permutation of 'Every %d week(s) on %lu days' use argument(s) at position 1 (stringsdict_entry_has_unused_arguments)")
        XCTAssertEqual(
            problemReporter.problems[6].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Base.stringsdict:6: ignored: Argument 1 in permutation 'Every %d weeks on %2$lu days of 'Every %d week(s) on %lu days' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)")
        XCTAssertEqual(
            problemReporter.problems[7].messageForXcode,
            "\(packageRootPath)/Examples/Demo_Translation.stringsdict:6: warning: 'Every %d week(s) on %lu days' does not use argument 1 (stringsdict_entry_missing_argument)")
    }
}
