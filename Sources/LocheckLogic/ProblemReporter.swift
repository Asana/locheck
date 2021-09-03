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
    case ignored
}

public protocol Problem {
    var kindIdentifier: String { get }
    var uniquifyingInformation: String { get }
    var severity: Severity { get }
    var message: String { get }
}

public protocol SummarizableProblem: Problem {
    // Provide the string key, allowing errors to be grouped and displayed in a nice
    // human-readable format
    var key: String { get }
}

/**
 Collect problems found during a run, and log them to the console for Xcode integration if desired.
 */
public class ProblemReporter {
    public struct LocalProblem: Error, Equatable {
        public let path: String
        public let lineNumber: Int
        public let problem: Problem

        var messageForXcode: String {
            "\(path):\(lineNumber): \(problem.severity.rawValue): \(problem.message) (\(problem.kindIdentifier))"
        }

        public static func == (a: LocalProblem, b: LocalProblem) -> Bool {
            a.path == b.path && a.lineNumber == b.lineNumber && a.messageForXcode == b.messageForXcode
        }
    }

    private var standardError = StderrOutputStream()
    public private(set) var problems = [LocalProblem]()

    /// Path prefix for all problems. Used to remove the prefix from the summary for readability.
    public let root: String
    public var log: Bool
    public let ignoredProblemIdentifiers: Set<String>
    public let ignoreWarnings: Bool

    public init(
        root: String = "",
        log: Bool = true,
        ignoredProblemIdentifiers: [String] = [],
        ignoreWarnings: Bool = false) {
        self.root = root
        self.log = log
        self.ignoredProblemIdentifiers = Set(ignoredProblemIdentifiers)
        self.ignoreWarnings = ignoreWarnings
    }

    public func report(_ problem: Problem, path: String, lineNumber: Int) {
        guard !ignoredProblemIdentifiers
            .contains(problem.kindIdentifier) && (!ignoreWarnings || problem.severity == .error) else { return }
        let localProblem = LocalProblem(path: path, lineNumber: lineNumber, problem: problem)
        problems.append(localProblem)

        guard log, problem.severity != .ignored else { return }
        // Print to stderr with formatting for Xcode error reporting
        print(localProblem.messageForXcode, to: &standardError)
    }

    public func printSummary() {
        guard problems.contains(where: { $0.problem.severity != .ignored }) else { return }
        var problemsByFile = [String: [LocalProblem]]()
        for localProblem in problems where localProblem.problem.severity != .ignored {
            if problemsByFile[localProblem.path] == nil {
                problemsByFile[localProblem.path] = []
            }
            problemsByFile[localProblem.path]!.append(localProblem)
        }

        print("\nSummary:")

        for path in problemsByFile.keys.sorted() {
            var pathToPrint = path
            if path.hasPrefix(root) {
                pathToPrint = String(pathToPrint.dropFirst(root.count))
            }
            if path.hasPrefix("/") {
                pathToPrint = String(pathToPrint.dropFirst())
            }
            print(pathToPrint)

            for problem in problemsByFile[path]!.filter({ $0.problem as? SummarizableProblem == nil }) {
                print(
                    "  \(problem.problem.severity.rawValue.uppercased()): \(problem.problem.message) (\(problem.problem.kindIdentifier))")
            }

            let summarizableProblems = problemsByFile[path]!.compactMap { $0.problem as? SummarizableProblem }
            let keys = Set(summarizableProblems.map(\.key))
            for key in keys.sorted() {
                print("  \(key):")
                for problem in summarizableProblems.filter({ $0.key == key }) {
                    print(
                        "    \(problem.severity.rawValue.uppercased()): \(problem.message) (\(problem.kindIdentifier))")
                }
            }
        }

        let warningCount = problems.filter { $0.problem.severity == .warning }.count
        let errorCount = problems.filter { $0.problem.severity == .error }.count
        let aggregates: [String] = [
            warningCount == 1 ? "1 warning" : "\(warningCount) warnings",
            errorCount == 1 ? "1 error" : "\(errorCount) errors",
        ]
        print(aggregates.joined(separator: ", "))

        if !ignoredProblemIdentifiers.isEmpty {
            print("Ignored", ignoredProblemIdentifiers.joined(separator: ", "))
        }
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
