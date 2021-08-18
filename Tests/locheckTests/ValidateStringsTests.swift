//
//  ValidateStringsTests.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

@testable import LocheckLogic
import XCTest

struct FakeFile: Filing {
  let path: String
  let nameExcludingExtension: String
}

class ValidateStringsTests: XCTestCase {
  func testMissing() {
    let problemReporter = ProblemReporter()
    problemReporter.log = false
    validateStrings(
      primaryStrings: [
        LocalizedString(
          key: "present", string: "present", file: FakeFile(path: "abc", nameExcludingExtension: "xyz"), line: 0,
          arguments: []),
        LocalizedString(
          key: "missing", string: "missing", file: FakeFile(path: "abc", nameExcludingExtension: "xyz"), line: 1,
          arguments: []),
      ],
      secondaryStrings: [
        LocalizedString(
          key: "present", string: "tneserp", file: FakeFile(path: "def", nameExcludingExtension: "uvw"), line: 0,
          arguments: []),
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)

    XCTAssertEqual(
      problemReporter.problems, [
        ProblemReporter.Problem(
          path: "abc", lineNumber: 1, message: "This string is missing from secondary", severity: .warning),
      ])
    XCTAssertEqual(problemReporter.problems.count, 1)
  }
}
