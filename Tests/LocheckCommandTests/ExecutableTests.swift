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
        process.arguments = ["strings", "Examples/Demo_Base.strings", "Examples/Demo_Translation.strings"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        print(stdout!)
        XCTAssertEqual(stdout!, """
        Validating Examples/Demo_Translation.strings against Examples/Demo_Base.strings

        SUMMARY:
        Examples/Demo_Base.strings
          missing:
            This string is missing from Demo_Translation
        Examples/Demo_Translation.strings
          bad pos %ld %@:
            Does not include argument(s) at 1
            Some arguments appear more than once in this translation
            Specifier for argument 2 does not match (should be @, is ld)
          bad position %d:
            Does not include argument(s) at 1
          mismatch %@ types %d:
            Specifier for argument 1 does not match (should be @, is d)
            Specifier for argument 2 does not match (should be d, is @)
        Errors found

        """)

        XCTAssertEqual(stderr, """
        Examples/Demo_Base.strings:3: warning: This string is missing from Demo_Translation (strings_key_missing_from_translation)
        Examples/Demo_Translation.strings:3: warning: Does not include argument(s) at 1 (string_has_missing_arguments)
        Examples/Demo_Translation.strings:3: warning: Some arguments appear more than once in this translation (string_has_duplicate_arguments)
        Examples/Demo_Translation.strings:3: error: Specifier for argument 2 does not match (should be @, is ld) (string_has_invalid_argument)
        Examples/Demo_Translation.strings:5: error: Specifier for argument 2 does not match (should be d, is @) (string_has_invalid_argument)
        Examples/Demo_Translation.strings:5: error: Specifier for argument 1 does not match (should be @, is d) (string_has_invalid_argument)
        Examples/Demo_Translation.strings:7: warning: Does not include argument(s) at 1 (string_has_missing_arguments)

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

        SUMMARY:
        Examples/Demo_Base.stringsdict
          %d/%d Completed:
            '%d/%d Completed' is missing from the the Demo_Translation translation
          missing from translation:
            'missing from translation' is missing from the the Demo_Translation translation
        Examples/Demo_Translation.stringsdict
          Every %d week(s) on %lu days:
            'Every %d week(s) on %lu days' does not use argument 1
            No permutation of 'Every %d week(s) on %lu days' use argument(s) at position 1
            Two permutations of 'Every %d week(s) on %lu days' contain different format specifiers at position 2. '%2$lu jours toutes les %d semaines' uses 'lu', and '%2$lu jours toutes les %d semaines' uses 'd'.
          missing from base:
            'missing from base' is missing from the base translation
        Errors found

        """)

        XCTAssertEqual(stderr, """
        Examples/Demo_Base.stringsdict:0: warning: '%d/%d Completed' is missing from the the Demo_Translation translation (stringsdict_key_missing_from_translation)
        Examples/Demo_Base.stringsdict:0: warning: 'missing from translation' is missing from the the Demo_Translation translation (stringsdict_key_missing_from_translation)
        Examples/Demo_Translation.stringsdict:0: warning: 'missing from base' is missing from the base translation (stringsdict_key_missing_from_base)
        Examples/Demo_Translation.stringsdict:0: error: Two permutations of 'Every %d week(s) on %lu days' contain different format specifiers at position 2. '%2$lu jours toutes les %d semaines' uses 'lu', and '%2$lu jours toutes les %d semaines' uses 'd'. (stringsdict_entry_permutations_have_conflicting_specifiers)
        Examples/Demo_Translation.stringsdict:0: warning: No permutation of 'Every %d week(s) on %lu days' use argument(s) at position 1 (stringsdict_entry_has_unused_arguments)
        Examples/Demo_Translation.stringsdict:0: warning: 'Every %d week(s) on %lu days' does not use argument 1 (stringsdict_entry_missing_argument)

        """)
    }
}
