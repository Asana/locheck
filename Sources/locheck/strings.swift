//
//  strings.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

import func Darwin.fputs
import var Darwin.stderr

struct StderrOutputStream: TextOutputStream {
  mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}

var standardError = StderrOutputStream()

extension NSTextCheckingResult {
  func getGroupStrings(original: String) -> [String] {
    (0 ..< numberOfRanges).compactMap { i in
      let matchRange = range(at: i)
      if matchRange == NSRange(original.startIndex ..< original.endIndex, in: original) {
        return nil
      } else if let substringRange = Range(matchRange, in: original) {
        return String(original[substringRange])
      } else {
        return nil
      }
    }
  }
}

struct FormatArgument {
  let specifier: String
  let position: Int
}

extension FormatArgument {
  init(specifier: String, positionString: String) {
    self.specifier = specifier
    position = NumberFormatter().number(from: positionString)!.intValue
  }
}

struct LocalizedString {
  let key: String
  let string: String
  let arguments: [FormatArgument]
  let line: Int

  init(key: String, string: String, line: Int) {
    self.key = key
    self.string = string
    self.line = line
    arguments = LocalizedString.parseArguments(string: string)
  }

  init?(string: String, line: Int) {
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
    arguments = LocalizedString.parseArguments(string: value)
  }

  static func parseArguments(string: String) -> [FormatArgument] {
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
            print("XXX", string.debugDescription, groupStrings.debugDescription)
            return nil
          }
          return FormatArgument(
            specifier: groupStrings.last!,
            position: i + 1)
        }
    }
  }
}

extension File {
  var lines: [String] {
    try! readAsString().split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map { String($0) }
  }
}

func validateStrings(primary: File, secondary: File, secondaryName: String) {
  print("Validating \(secondary.path) against \(primary.path)")
  var secondaryStrings = [String: LocalizedString]()
  for (i, line) in secondary.lines.enumerated() {
    guard let localizedString = LocalizedString(string: line, line: i) else { continue }
    secondaryStrings[localizedString.key] = localizedString
  }

  for (i, line) in primary.lines.enumerated() {
    guard let primaryString = LocalizedString(string: line, line: i) else { continue }

    guard let secondaryString = secondaryStrings[primaryString.key] else {
      print(
        "\(primary.path):\(i + 1): warning: This string is missing from \(secondaryName)",
        to: &standardError)
      continue
    }

    let hasSamePositions = Set(primaryString.arguments.map(\.position)) == Set(secondaryString.arguments.map(\.position))
    if !hasSamePositions {
      print("\(secondary.path):\(i + 1): error: Number or value of positions do not match", to: &standardError)
    }

    let primaryTypes = primaryString.arguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
    let secondaryTypes = secondaryString
      .arguments.sorted(by: { $0.position < $1.position }).map(\.specifier)
    if primaryTypes != secondaryTypes {
      print(
        "\(secondary.path):\(i + 1): error: Specifiers do not match. Original: \(primaryTypes), translated: \(secondaryTypes)",
        to: &standardError)
    }
  }
}
