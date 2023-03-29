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
        XCTAssertEqual(
            problemReporter.problems
                .map(\.messageForXcode)
                .map { $0.replacingOccurrences(of: "\(packageRootPath)/", with: "") }
                .joined(separator: "\n"),
            """
            Examples/Demo_Base.stringsdict:22: warning: '%d/%d Completed' is missing from Demo_Translation (key_missing_from_translation)
            Examples/Demo_Base.stringsdict:81: warning: '%s added %d task(s) to 's'' is missing from Demo_Translation (key_missing_from_translation)
            Examples/Demo_Base.stringsdict:63: warning: 'missing from translation' is missing from Demo_Translation (key_missing_from_translation)
            Examples/Demo_Translation.stringsdict:22: warning: 'missing from base' is missing from the base translation (key_missing_from_base)
            Examples/Demo_Base.stringsdict:6: ignored: Argument 1 in permutation 'Every %d weeks on %2$lu days' of 'Every %d week(s) on %lu days' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 1 in permutation '%s added %d tasks and %d milestones to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 2 in permutation '%s added %d tasks and %d milestones to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 3 in permutation '%s added %d tasks and %d milestones to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added %d tasks and %d milestones to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 1 in permutation '%s added %d tasks and a milestone to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 2 in permutation '%s added %d tasks and a milestone to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added %d tasks and a milestone to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 1 in permutation '%s added a task and %d milestones to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 2 in permutation '%s added a task and %d milestones to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added a task and %d milestones to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            Examples/Demo_Base.stringsdict:81: ignored: Argument 1 in permutation '%s added a task and a milestone to %3$s' of '%s added %d task(s) to 's'' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added a task and a milestone to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            Examples/Demo_Translation.stringsdict:6: ignored: Argument 1 in permutation '%2$lu jours toutes les %d semaines' of 'Every %d week(s) on %lu days' has an implicit position. Use an explicit position for safety. (stringsdict_entry_has_implicit_position)
            """)
    }
}
