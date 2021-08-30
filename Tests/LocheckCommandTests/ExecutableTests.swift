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

        XCTAssertEqual(stdout, """
        Validating Examples/Demo_Translation.strings against Examples/Demo_Base.strings
        Errors found

        """)

        XCTAssertEqual(stderr, """
        Examples/Demo_Base.strings:3: warning: This string is missing from Demo_Translation
        Examples/Demo_Translation.strings:3: warning: Does not include argument(s) at 1
        Examples/Demo_Translation.strings:3: warning: Some arguments appear more than once in this translation
        Examples/Demo_Translation.strings:3: error: Specifier for argument 2 does not match (should be @, is ld)
        Examples/Demo_Translation.strings:5: error: Specifier for argument 2 does not match (should be d, is @)
        Examples/Demo_Translation.strings:5: error: Specifier for argument 1 does not match (should be @, is d)
        Examples/Demo_Translation.strings:7: warning: Does not include argument(s) at 1

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

        XCTAssertEqual(stdout, """
        Finished validating

        """)

        XCTAssertEqual(stderr, """
        Examples/Demo_Base.stringsdict:0: warning: '%d/%d Completed' is missing from the the Demo_Translation translation
        Examples/Demo_Base.stringsdict:0: warning: 'missing from translation' is missing from the the Demo_Translation translation
        Examples/Demo_Translation.stringsdict:0: warning: 'missing from base' is missing from the base translation

        """)
    }
}
