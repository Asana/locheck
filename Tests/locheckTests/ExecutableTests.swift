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

    func testExampleOutput() throws {
        let binary = productsDirectory.appendingPathComponent("locheck")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["strings", "Examples/Demo1.strings", "Examples/Demo2.strings"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        XCTAssertEqual(stdout, """
        Validating Examples/Demo2.strings against Examples/Demo1.strings
        Errors found

        """)

        XCTAssertEqual(stderr, """
        Examples/Demo1.strings:3: warning: This string is missing from Demo2
        Examples/Demo2.strings:3: warning: Some arguments appear more than once in this translation
        Examples/Demo2.strings:3: error: Specifier for argument 2 does not match (should be @, is ld)
        Examples/Demo2.strings:5: error: Specifier for argument 2 does not match (should be d, is @)
        Examples/Demo2.strings:5: error: Specifier for argument 1 does not match (should be @, is d)

        """)
    }
}
