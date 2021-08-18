//
//  ProblemReporter.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import func Darwin.fputs
import var Darwin.stderr
import Foundation

private struct StderrOutputStream: TextOutputStream {
  mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}

class ProblemReporter {
  struct Problem: Error {
    enum Severity: String {
      case warning
      case error
    }

    let path: String
    let lineNumber: Int
    let message: String
    let severity: Severity
  }

  private var standardError = StderrOutputStream()
  private var problems = [Problem]()

  func report(_ severity: Problem.Severity, path: String, lineNumber: Int, message: String) {
    problems.append(Problem(path: path, lineNumber: lineNumber, message: message, severity: severity))

    // Print to stderr with formatting for Xcode error reporting
    print("\(path):\(lineNumber): \(severity.rawValue): \(message)", to: &standardError)
  }

  var hasError: Bool { problems.contains(where: { $0.severity == .error }) }
}
