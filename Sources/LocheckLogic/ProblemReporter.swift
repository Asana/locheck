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

public class ProblemReporter {
    public struct Problem: Error, Equatable {
        public enum Severity: String {
            case warning
            case error
        }

        public let path: String
        public let lineNumber: Int
        public let message: String
        public let severity: Severity
    }

    private var standardError = StderrOutputStream()
    public private(set) var problems = [Problem]()

    public var log: Bool

    public init(log: Bool = true) {
        self.log = log
    }

    public func report(_ severity: Problem.Severity, path: String, lineNumber: Int, message: String) {
        problems.append(Problem(path: path, lineNumber: lineNumber, message: message, severity: severity))

        guard log else { return }
        // Print to stderr with formatting for Xcode error reporting
        print("\(path):\(lineNumber): \(severity.rawValue): \(message)", to: &standardError)
    }

    public var hasError: Bool { problems.contains(where: { $0.severity == .error }) }

    public func logInfo(_ string: String) {
        guard log else { return }
        print(string)
    }
}
