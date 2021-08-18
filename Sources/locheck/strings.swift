//
//  strings.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

private struct FormatArgument {
  let specifier: String
  let position: Int
}

private extension FormatArgument {
  init(specifier: String, positionString: String) {
    self.specifier = specifier
    position = NumberFormatter().number(from: positionString)!.intValue
  }
}

private struct LocalizedString {
  let key: String
  let string: String
  let arguments: [FormatArgument]
  let line: Int

  init(key: String, string: String, line: Int, problemReporter: ProblemReporter) {
    self.key = key
    self.string = string
    self.line = line
    arguments = LocalizedString.parseArguments(string: string, problemReporter: problemReporter)
  }

  init?(string: String, line: Int, problemReporter: ProblemReporter) {
    // https://stackoverflow.com/a/37032779
    let stringPattern = "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\""
    let pattern = "^(\(stringPattern)) = (\(stringPattern));$"
    let stringLiteralRegex = try! NSRegularExpression(
      pattern: pattern,
      options: .anchorsMatchLines)
    guard let strings = stringLiteralRegex
      .matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
      .first?
      .getGroupStrings(original: string) else {
      return nil
    }
    guard strings.count == 2 else {
//      print(string)
//      print(strings.debugDescription)
//      assert(strings.count == 0)
      return nil
    }
    let key = String(strings[0].dropFirst().dropLast())
    let value = String(strings[1].dropFirst().dropLast())
    self.key = key
    self.string = string
    self.line = line
    arguments = LocalizedString.parseArguments(string: value, problemReporter: problemReporter)
  }

  static func parseArguments(string: String, problemReporter: ProblemReporter) -> [FormatArgument] {
    if string.contains("$") {
      return try! NSRegularExpression(pattern: "%(\\d+)\\$([@a-z]+)", options: [])
        .matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        .compactMap { (match: NSTextCheckingResult) -> FormatArgument? in
          let groupStrings = match.getGroupStrings(original: string)
          return FormatArgument(
            specifier: groupStrings[2],
            positionString: groupStrings[1])
        }
    } else {
      return try! NSRegularExpression(pattern: "%([@a-z]+)", options: [])
        .matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        .enumerated()
        .compactMap { (i: Int, match: NSTextCheckingResult) -> FormatArgument? in
          let groupStrings = match.getGroupStrings(original: string)
          guard !groupStrings.isEmpty else {
            problemReporter.logInfo("XXX \(string.debugDescription) \(groupStrings.debugDescription)")
            return nil
          }
          return FormatArgument(
            specifier: groupStrings.last!,
            position: i + 1)
        }
    }
  }
}

func validateStrings(primary: File, secondary: File, secondaryName: String, problemReporter: ProblemReporter) {
  problemReporter.logInfo("Validating \(secondary.path) against \(primary.path)")
  var secondaryStrings = [String: LocalizedString]()
  for (i, line) in secondary.lines.enumerated() {
    guard let localizedString = LocalizedString(string: line, line: i, problemReporter: problemReporter) else { continue }
    secondaryStrings[localizedString.key] = localizedString
  }

  for (i, line) in primary.lines.enumerated() {
    guard let primaryString = LocalizedString(string: line, line: i, problemReporter: problemReporter) else { continue }

    guard let secondaryString = secondaryStrings[primaryString.key] else {
      problemReporter.report(
        .warning,
        path: primary.path,
        lineNumber: i + 1,
        message: "This string is missing from \(secondaryName)")
      continue
    }

    let hasSamePositions = Set(primaryString.arguments.map(\.position)) == Set(secondaryString.arguments.map(\.position))
    if !hasSamePositions {
      problemReporter.report(
        .error,
        path: secondary.path,
        lineNumber: i + 1,
        message: "Number or value of positions do not match")
    }

    let primaryTypes = primaryString.arguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
    let secondaryTypes = secondaryString
      .arguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
    if primaryTypes != secondaryTypes {
      problemReporter.report(
        .error,
        path: secondary.path,
        lineNumber: i + 1,
        message: "Specifiers do not match. Original: \(primaryTypes.joined(separator: ",")); translated: \(secondaryTypes.joined(separator: ","))")
    }
  }
}
