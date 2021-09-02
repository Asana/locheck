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

        print(stdout!)
        XCTAssertEqual(stdout!, """
        Validating Examples/Demo_Translation.strings against Examples/Demo_Base.strings

        Summary:
        Examples/Demo_Base.strings
          missing:
            WARNING: 'missing' is missing from Demo_Translation
        Examples/Demo_Translation.strings
          bad pos %ld %@:
            WARNING: 'bad pos %ld %@' does not include argument(s) at 1
            WARNING: Some arguments appear more than once in this translation
            ERROR: Specifier for argument 2 does not match (should be @, is ld)
          bad position %d:
            WARNING: 'bad position %d' does not include argument(s) at 1
          mismatch %@ types %d:
            ERROR: Specifier for argument 2 does not match (should be d, is @)
            ERROR: Specifier for argument 1 does not match (should be @, is d)
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
            WARNING: '%d/%d Completed' is missing from Demo_Translation
          missing from translation:
            WARNING: 'missing from translation' is missing from Demo_Translation
        Examples/Demo_Translation.stringsdict
          missing from base:
            WARNING: 'missing from base' is missing from the base translation
        3 warnings, 0 errors
        Finished validating

        """)

        XCTAssertEqual(stderr!, """
        Examples/Demo_Base.stringsdict:22: warning: '%d/%d Completed' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Base.stringsdict:63: warning: 'missing from translation' is missing from Demo_Translation (key_missing_from_translation)
        Examples/Demo_Translation.stringsdict:22: warning: 'missing from base' is missing from the base translation (key_missing_from_base)

        """)
    }
}
