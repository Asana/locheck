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
  func testValid_noArgs() {
    let problemReporter = ProblemReporter(log: false)
    validateStrings(
      primaryStrings: [
        LocalizedString(
          key: "present",
          string: "present",
          file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
          line: 0,
          arguments: []),
      ],
      secondaryStrings: [
        LocalizedString(
          key: "present",
          string: "tneserp",
          file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
          line: 0,
          arguments: []),
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)

    XCTAssertFalse(problemReporter.hasError)
    XCTAssertTrue(problemReporter.problems.isEmpty)
  }

  func testValid_implicitOrderArgs() {
    let problemReporter = ProblemReporter(log: false)
    validateStrings(
      primaryStrings: [
        LocalizedString(
          string: "\"present %d %@\" = \"present %d %@\";",
          file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
          line: 0,
          problemReporter: problemReporter)!,
      ],
      secondaryStrings: [
        LocalizedString(
          string: "\"present %d %@\" = \"%d %@\";",
          file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
          line: 0,
          problemReporter: problemReporter)!,
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)

    XCTAssertFalse(problemReporter.hasError)
    XCTAssertTrue(problemReporter.problems.isEmpty)
  }

  func testInvalid_implicitOrderArgs() {
    let problemReporter = ProblemReporter(log: false)
    validateStrings(
      primaryStrings: [
        LocalizedString(
          string: "\"present %d %@\" = \"present %d %@\";",
          file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
          line: 0,
          problemReporter: problemReporter)!,
      ],
      secondaryStrings: [
        LocalizedString(
          string: "\"present %d %@\" = \"%@ %d tneserp\";", // specifiers swapped
          file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
          line: 0,
          problemReporter: problemReporter)!,
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)

    XCTAssertTrue(problemReporter.hasError)
    XCTAssertEqual(
      problemReporter.problems,
      [
        ProblemReporter.Problem(
          path: "def",
          lineNumber: 0,
          message: "Specifiers do not match. Original: d,@; translated: @,d",
          severity: .error),
      ])
  }

  func testValid_explicitOrderArgs() {
    let problemReporter = ProblemReporter(log: false)
    validateStrings(
      primaryStrings: [
        LocalizedString(
          string: "\"present %1$d %2$@\" = \"present %1$d %2$@\";",
          file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
          line: 0,
          problemReporter: problemReporter)!,
      ],
      secondaryStrings: [
        LocalizedString(
          string: "\"present %1$d %2$@\" = \"tneserp %2$@ %1$d\";",
          file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
          line: 0,
          problemReporter: problemReporter)!,
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)

    XCTAssertFalse(problemReporter.hasError)
    XCTAssertTrue(problemReporter.problems.isEmpty)
  }

  func testMissing() {
    let problemReporter = ProblemReporter(log: false)
    validateStrings(
      primaryStrings: [
        LocalizedString(
          key: "present",
          string: "present",
          file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
          line: 0,
          arguments: []),
        LocalizedString(
          key: "missing",
          string: "missing", file: FakeFile(path: "abc", nameExcludingExtension: "xyz"),
          line: 1,
          arguments: []),
      ],
      secondaryStrings: [
        LocalizedString(
          key: "present",
          string: "tneserp",
          file: FakeFile(path: "def", nameExcludingExtension: "uvw"),
          line: 0,
          arguments: []),
      ],
      secondaryFileName: "secondary",
      problemReporter: problemReporter)

    XCTAssertEqual(
      problemReporter.problems, [
        ProblemReporter.Problem(
          path: "abc", lineNumber: 1, message: "This string is missing from secondary", severity: .warning),
      ])
  }
}
