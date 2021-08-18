//
//  strings.swift
//  
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

extension NSTextCheckingResult {
  func getGroupStrings(original: String) -> [String] {
    (0..<numberOfRanges).compactMap { i in
      let matchRange = range(at: i)
      if matchRange == NSRange(original.startIndex..<original.endIndex, in: original) {
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
  let position: Int? // nil = implicit
}

extension FormatArgument {
  init(specifier: String, positionString: String) {
    self.specifier = specifier
    self.position = NumberFormatter().number(from: positionString)!.intValue
  }
}

struct LocalizedString {
  let key: String
  let string: String
  let arguments: [FormatArgument]

  init(key: String, string: String) {
    self.key = key
    self.string = string
    self.arguments = LocalizedString.parseArguments(string: string)
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
          return FormatArgument(
            specifier: groupStrings[1],
            position: i)
        }
    }
  }
}

func validateStrings(primary: File, secondary: File) {
  print("Validating \(primary.path)")
  var secondaryStrings = [String: LocalizedString]()
  let lines = try! secondary.readAsString().split(whereSeparator: {
    $0.unicodeScalars.contains(where: CharacterSet.newlines.contains)
  }).map { String($0) }
  for line in lines {
    guard let localizedString = parseStringsLine(line) else { continue }
    print(line)
    secondaryStrings[localizedString.key] = localizedString
    print(localizedString)
    return
  }
}

func parseStringsLine(_ line: String) -> LocalizedString? {
  // https://stackoverflow.com/a/37032779
  let stringPattern = "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\""
  let pattern = "^(\(stringPattern)) = (\(stringPattern));$"
  let stringLiteralRegex = try! NSRegularExpression(
    pattern: pattern,
    options: .anchorsMatchLines)
  guard let strings = stringLiteralRegex
    .matches(in: line, options: [], range: NSRange(location: 0, length: line.count))
    .first?
    .getGroupStrings(original: line) else {
    return nil
  }
  guard strings.count == 2 else {
    assert(strings.count == 0)
    return nil
  }
  let key = String(strings[0].dropFirst().dropLast())
  let value = String(strings[1].dropFirst().dropLast())
  return LocalizedString(key: key, string: value)
}
