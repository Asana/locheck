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
          key: "present", string: "present", file: FakeFile(path: "abc", nameExcludingExtension: "xyz"), line: 0, arguments: []),
        LocalizedString(
          key: "missing", string: "missing", file: FakeFile(path: "abc", nameExcludingExtension: "xyz"), line: 0, arguments: []),
      ],
      secondaryStrings: [
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)
  }
}
