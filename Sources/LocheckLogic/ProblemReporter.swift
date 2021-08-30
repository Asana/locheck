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

public enum Severity: String {
    case warning
    case error
}

public protocol Problem {
    var identifier: String { get }
    var severity: Severity { get }
    var message: String { get }
}

/**
 Collect problems found during a run, and log them to the console for Xcode integration if desired.
 */
public class ProblemReporter {
    public struct LocalProblem: Error {
        public let path: String
        public let lineNumber: Int
        public let problem: Problem

        /// Unique identifier for this problem on this line of this file
        var identifier: String {
            "\(path)-\(lineNumber)-\(problem.identifier)"
        }
    }

    private var standardError = StderrOutputStream()
    public private(set) var problems = [LocalProblem]()

    public var log: Bool

    public init(log: Bool = true) {
        self.log = log
    }

    public func report(_ problem: Problem, path: String, lineNumber: Int) {
        problems.append(LocalProblem(path: path, lineNumber: lineNumber, problem: problem))

        guard log else { return }
        // Print to stderr with formatting for Xcode error reporting
        print("\(path):\(lineNumber): \(problem.severity.rawValue): \(problem.message)", to: &standardError)
    }

    /**
     Returns true iff an `.error`-severity problem has been reported. Returns `false` if no problems
     or only warnings were reported.
     */
    public var hasError: Bool {
        problems.contains(where: { $0.problem.severity == .error })
    }

    /**
     Forwards to `print()` iff `log == true`, otherwise does nothing
     */
    public func logInfo(_ string: String) {
        guard log else { return }
        print(string)
    }
}
