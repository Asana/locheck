//
//  ExecutableTests.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import class Foundation.Bundle
import XCTest

class ExecutableTests: XCTestCase {
    fileprivate let packageRootPath = URL(fileURLWithPath: #file)
        .pathComponents
        .prefix(while: { $0 != "Tests" })
        .joined(separator: "/")
        .dropFirst()

    /// Returns path to the built products directory.
    var productsDirectory: URL {
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
    }

    override func setUp() {
        super.setUp()
        FileManager.default.changeCurrentDirectoryPath(String(packageRootPath))
    }

    override class func tearDown() {
        super.tearDown()
    }

    func testExampleOutput_strings() throws {
        let binary = productsDirectory.appendingPathComponent("locheck")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["xcstrings", "Examples/Demo_Base.strings", "Examples/Demo_Translation.strings"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        XCTAssertEqual(stdout!, """

        Summary:
        Examples/Demo_Base.strings
          missing:
            WARNING: 'missing' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Translation.strings
          bad pos %ld %@:
            WARNING: 'bad pos %ld %@' does not include argument(s) at 1 (string_has_missing_arguments)
              Base: %1$ld %2$@
              Translation: %2$ld %2$@
            WARNING: Some arguments appear more than once in this translation (string_has_duplicate_arguments)
              Base: %1$ld %2$@
              Translation: %2$ld %2$@
            ERROR: Specifier for argument 2 does not match (should be @, is ld) (string_has_invalid_argument)
              Base: %1$ld %2$@
              Translation: %2$ld %2$@
          bad position %d:
            WARNING: 'bad position %d' does not include argument(s) at 1 (string_has_missing_arguments)
              Base: bad position %d
              Translation: bad position %$d
          mismatch %@ types %d:
            ERROR: Specifier for argument 2 does not match (should be d, is @) (string_has_invalid_argument)
              Base: mismatch %@ types %d
              Translation: mismatch %2$@ types %1$d
            ERROR: Specifier for argument 1 does not match (should be @, is d) (string_has_invalid_argument)
              Base: mismatch %@ types %d
              Translation: mismatch %2$@ types %1$d
        4 warnings, 3 errors
        Errors found

        """)

        XCTAssertEqual(stderr!, """
        Examples/Demo_Base.strings:3: warning: 'missing' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Translation.strings:3: warning: 'bad pos %ld %@' does not include argument(s) at 1 (string_has_missing_arguments)
        Examples/Demo_Translation.strings:3: warning: Some arguments appear more than once in this translation (string_has_duplicate_arguments)
        Examples/Demo_Translation.strings:3: error: Specifier for argument 2 does not match (should be @, is ld) (string_has_invalid_argument)
        Examples/Demo_Translation.strings:5: error: Specifier for argument 2 does not match (should be d, is @) (string_has_invalid_argument)
        Examples/Demo_Translation.strings:5: error: Specifier for argument 1 does not match (should be @, is d) (string_has_invalid_argument)
        Examples/Demo_Translation.strings:7: warning: 'bad position %d' does not include argument(s) at 1 (string_has_missing_arguments)

        """)
    }

    func testExampleOutput_stringsdict() throws {
        let binary = productsDirectory.appendingPathComponent("locheck")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["stringsdict", "Examples/Demo_Base.stringsdict", "Examples/Demo_Translation.stringsdict"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        XCTAssertEqual(stdout!, """

        Summary:
        Examples/Demo_Base.stringsdict
          %d/%d Completed:
            WARNING: '%d/%d Completed' is missing from Demo_Translation (key_missing_from_translation)
          %s added %d task(s) to 's':
            WARNING: '%s added %d task(s) to 's'' is missing from Demo_Translation (key_missing_from_translation)
            ERROR: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added %d tasks and %d milestones to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            ERROR: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added %d tasks and a milestone to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            ERROR: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added a task and %d milestones to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
            ERROR: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added a task and a milestone to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
          missing from translation:
            WARNING: 'missing from translation' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Translation.stringsdict
          missing from base:
            WARNING: 'missing from base' is missing from the base translation (key_missing_from_base)
        4 warnings, 4 errors
        Errors found

        """)

        XCTAssertEqual(stderr!, """
        Examples/Demo_Base.stringsdict:22: warning: '%d/%d Completed' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Base.stringsdict:81: warning: '%s added %d task(s) to 's'' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Base.stringsdict:63: warning: 'missing from translation' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Translation.stringsdict:22: warning: 'missing from base' is missing from the base translation (key_missing_from_base)
        Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added %d tasks and %d milestones to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
        Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added %d tasks and a milestone to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
        Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added a task and %d milestones to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)
        Examples/Demo_Base.stringsdict:81: error: Two permutations of '%s added %d task(s) to 's'' contain different format specifiers at position 3. '%s added %d tasks and %d milestones to %3$s' uses 'd', and '%s added a task and a milestone to %3$s' uses 's'. (stringsdict_entry_permutations_have_conflicting_specifiers)

        """)
    }

    func testExampleOutput_lproj() throws {
        let binary = productsDirectory.appendingPathComponent("locheck")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["lproj", "Examples/test-base.lproj", "Examples/test-translation.lproj"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        XCTAssertEqual(stdout!, """
        Validating 1 lproj files against test-base.lproj

        Summary:
        Examples/test-base.lproj/file1.strings
          just_in_file1:
            WARNING: 'just_in_file1' is missing from test-translation (key_missing_from_translation)
        Examples/test-base.lproj/file2.strings
          in_both_files:
            WARNING: 'in_both_files' is missing from test-translation (key_missing_from_translation)
        2 warnings, 0 errors
        Finished validating

        """)

        XCTAssertEqual(stderr!, """
        Examples/test-base.lproj/file1.strings:2: warning: 'just_in_file1' is missing from test-translation (key_missing_from_translation)
        Examples/test-base.lproj/file2.strings:1: warning: 'in_both_files' is missing from test-translation (key_missing_from_translation)

        """)
    }

  func testExampleOutput_android() throws {
    let binary = productsDirectory.appendingPathComponent("locheck")

    let process = Process()
    process.executableURL = binary
    process.arguments = ["androidstrings", "Examples/strings-base.xml", "Examples/strings-translation.xml"]

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

    XCTAssertEqual(stdout!, """

        Summary:
        Examples/strings-base.xml
          missing_from_translation:
            WARNING: 'missing_from_translation' is missing from Examples (key_missing_from_translation)
          translation_missing_string_array:
            WARNING: 'translation_missing_string_array' is missing from Examples (key_missing_from_translation)
        Examples/strings-translation.xml
          base_missing_string_array:
            WARNING: 'base_missing_string_array' is missing from the base translation (key_missing_from_base)
          missing_from_base:
            WARNING: 'missing_from_base' is missing from the base translation (key_missing_from_base)
          string_array_wrong_item_count:
            WARNING: 'string_array_wrong_item_count' item count mismatch in Examples: 2 (should be 1) (string_array_item_count_mismatch)
          translation_has_invalid_specifier:
            ERROR: Specifier for argument 2 does not match (should be d, is lu) (string_has_invalid_argument)
          translation_has_missing_arg:
            WARNING: 'translation_has_missing_arg' does not include argument(s) at 2 (string_has_missing_arguments)
          translation_has_missing_phrase:
            WARNING: 'translation_has_missing_phrase' does not include argument(s): object_name (phrase_has_missing_arguments)
        7 warnings, 1 error
        Errors found

        """)

    XCTAssertEqual(stderr!, """
        Examples/strings-base.xml:28: warning: 'missing_from_translation' is missing from Examples (key_missing_from_translation)
        Examples/strings-translation.xml:25: warning: 'missing_from_base' is missing from the base translation (key_missing_from_base)
        Examples/strings-base.xml:36: warning: 'translation_missing_string_array' is missing from Examples (key_missing_from_translation)
        Examples/strings-translation.xml:33: warning: 'base_missing_string_array' is missing from the base translation (key_missing_from_base)
        Examples/strings-translation.xml:17: warning: 'translation_has_missing_phrase' does not include argument(s): object_name (phrase_has_missing_arguments)
        Examples/strings-translation.xml:21: error: Specifier for argument 2 does not match (should be d, is lu) (string_has_invalid_argument)
        Examples/strings-translation.xml:22: warning: 'translation_has_missing_arg' does not include argument(s) at 2 (string_has_missing_arguments)
        Examples/strings-translation.xml:38: warning: 'string_array_wrong_item_count' item count mismatch in Examples: 2 (should be 1) (string_array_item_count_mismatch)

        """)
  }
}
