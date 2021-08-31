//
//  StringsdictEntry.swift
//
//
//  Created by Steve Landey on 8/25/21.
//

import Foundation
import SwiftyXMLParser

/// These structs may also be referred to as "grammars" because that is the formal name
/// for a system of rules defining a set of strings.
struct StringsdictEntry: Equatable {
    let key: String
    let formatKey: LexedStringsdictString
    let rules: [String: StringsdictRule] // derived from XML

    func validateRuleVariables(path: String, problemReporter: ProblemReporter) {
        let checkRule = { (ruleKey: String, variables: [String]) -> Void in
            for variable in variables where rules[variable] == nil {
                // lineNumber is nil because we don't have it from SwiftyXMLParser.
                problemReporter.report(
                    StringsdictEntryHasMissingVariable(
                        key: key,
                        variable: variable,
                        ruleKey: ruleKey),
                    path: path,
                    lineNumber: nil)
            }
        }

        checkRule("the format key", formatKey.variables)
        for rule in rules.values.sorted(by: { $0.key < $1.key }) {
            for (alternativeKey, alternative) in rule.alternatives {
                checkRule("'\(rule.key)'.\(alternativeKey)", alternative.variables)
            }
        }
    }

    /**
     Generates all permutations of this entry, resulting in a bunch of related format strings:

     ```
     "One apple and %2$d oranges"
     "%d apples and %2$d oranges"
     "One apple and one orange"
     "%d apples and one orange"
     ```

     It then builds a "canonical" list of `FormatArgument` values representing the "correct"
     specifier for each argument position, and logs problems if there are any mismatches or
     missing values.
     */
    func getCanonicalArgumentList(path: String, problemReporter: ProblemReporter) -> [FormatArgument?] {
        // One nice improvement here would be to ensure that each argument is only used in one variable,
        // but that would require us to remember which span of each string maps back to which variable,
        // which is a lot of extra bookkeeping to do at this stage of the project.

        let report = { (problem: Problem) -> Void in
            // lineNumber is nil because we don't have it from SwiftyXMLParser.
            problemReporter.report(problem, path: path, lineNumber: nil)
        }

        let permutations = allPermutations.map { FormatString(string: $0, path: path, line: nil) }
        let numArgs = permutations.flatMap(\.arguments).reduce(0) { max($0, $1.position) }
        var arguments = [FormatArgument?]((0 ..< numArgs).map { _ in nil })
        var originalStringForArgument = [String]((0 ..< numArgs).map { _ in "" })

        for string in permutations {
            for arg in string.arguments {
                if !arg.isPositionExplicit {
                    report(
                        StringsdictEntryHasImplicitPosition(
                            key: key,
                            position: arg.position,
                            permutation: string.string))
                }

                // Remember arg positions are 1-indexed!
                if let oldArg = arguments[arg.position - 1] {
                    if arg.specifier != oldArg.specifier {
                        let originalString = originalStringForArgument[oldArg.position - 1]
                        report(
                            StringsdictEntryPermutationsHaveConflictingSpecifiers(
                                key: key,
                                position: arg.position,
                                permutation1: originalString,
                                permutation2: string.string,
                                specifier1: oldArg.specifier,
                                specifier2: arg.specifier))
                    }
                } else {
                    originalStringForArgument[arg.position - 1] = string.string
                    arguments[arg.position - 1] = arg
                }
            }
        }

        let unusedArguments = arguments.enumerated().filter { $0.1 == nil }.map(\.0)
        if !unusedArguments.isEmpty {
            report(
                StringsdictEntryHasUnusedArguments(
                    key: key,
                    positions: unusedArguments))
        }

        return arguments
    }

    /**
     Generate every possible permutation of this string. For example, if your format key is
     `%#@abc@` and you have a rule `abc` with variants `one="xxx"` and `other="yyy"`, this
     getter will return `["xxx", "yyy"]`.

     In order to be comprehensive, it needs to recursively expand every rule, including nested
     rules.

     Example input:
     ```
     transportation:
        format key: "%#@cars@ and %#@motorcycles@"
        cars:
            one: "one car"
            other: "%1$d cars"
        motorcycles:
            one: "one motorcycle with %#@sidecars@"
            other: "%2$d motorcycle with %#@sidecars@"
        sidecars:
            zero: "no sidecar"
            one: "one sidecar"
            other: "%3$d sidecars"
     ```

     Example output:
     ```
     [
         "one car and one motorcycle with no sidecar",
         "one car and one motorcycle with one sidecar",
         "one car and one motorcycle with %3$d sidecars",
         "one car and %2$d motorcycles with no sidecar",
         "one car and %2$d motorcycles with one sidecar",
         "one car and %2$d motorcycles with %3$d sidecars",
         "%1$d cars and one motorcycle with no sidecar",
         "%1$d cars and one motorcycle with one sidecar",
         "%1$d cars and one motorcycle with %3$d sidecars",
         "%1$d cars and %2$d motorcycles with no sidecar",
         "%1$d cars and %2$d motorcycles with one sidecar",
         "%1$d cars and %2$d motorcycles with %3$d sidecars",
     ]
     ```
     */
    var allPermutations: [String] {
        getAllPermutations(of: formatKey)
    }

    /**
     For a given LexedStringsdictString, keep track of the parts for which we've
     decided on a constant string. The length of `resolvedParts` is less than or
     equal to the length of `string.parts` because it contains only decisions the
     algorithm has made.
     */
    private struct PartialPermutation {
        let string: LexedStringsdictString
        var resolvedParts: [String]

        /// Return the next unresolved part of the string. May be nil if we have
        /// resolved all parts.
        var nextPart: LexedStringsdictString.Part? {
            if resolvedParts.count < string.parts.count {
                return string.parts[resolvedParts.count]
            } else {
                return nil
            }
        }
    }

    func getAllPermutations(of string: LexedStringsdictString) -> [String] {
        // Maintain a list of partial permutations. We will append to this list from
        // the return value of `expand()`. The base case is the string passed as an
        // argument, with no resolved parts.
        var toExpand = [PartialPermutation(string: string, resolvedParts: [])]
        var results = [String]()

        while !toExpand.isEmpty {
            let p = toExpand.removeFirst()
            let (newPartialPermutations, newResults) = expand(p)
            toExpand.append(contentsOf: newPartialPermutations)
            results.append(contentsOf: newResults)
        }

        return results
    }

    /**
     Given a partial permutation, i.e. a `LexedStringsdictString` with zero or more parts
     replaced by constant strings, return the "next step" in the process. That could be either
     a new string to add to the result set (if all parts are resolved), a modified copy of the
     input permutation (if the next part is a constant string), or a list of new partial
     permutations derived by recursively calling `getAllPermutations()` (if the next part is a
     variable).
     */
    private func expand(_ p: PartialPermutation) -> ([PartialPermutation], [String]) {
        switch p.nextPart {
        case .none:
            return ([], [p.resolvedParts.joined()])
        case .some(.constant(let constant)):
            var newPermutation = p
            // We can immediately "resolve" this because it's a constant string
            newPermutation.resolvedParts.append(constant)
            return ([newPermutation], [])
        case .some(.variable(let variable)):
            var nextPermutations = [PartialPermutation]()
            // ! is safe because we validated rules at init time
            let rule = rules[variable]!
            // For each alternative, recurse into `getAllPermutations()`, which returns a list of
            // all possible strings that could be generated by this grammar. For each of those
            // strings, return a partial permutation using that string in place of the variable.
            //
            // Don't bother caching because deep hierarchies are very rare and this is fast.
            for alternative in rule.alternatives.values.sorted(by: { $0.string < $1.string }) {
                for substring in getAllPermutations(of: alternative) {
                    nextPermutations.append(
                        PartialPermutation(
                            string: p.string,
                            resolvedParts: p.resolvedParts + [substring]))
                }
            }
            return (nextPermutations, [])
        }
    }
}

extension StringsdictEntry {
    init?(key: String, node: XML.Element, path: String, problemReporter: ProblemReporter) {
        let report = { (problem: Problem) -> Void in
            // lineNumber is nil because we don't have it from SwiftyXMLParser.
            problemReporter.report(problem, path: path, lineNumber: nil)
        }

        var maybeFormatKey: String?
        var rules = [String: StringsdictRule]()
        var maybeOrderedRuleKeys: [String]?

        for (valueKey, valueNode) in readPlistDict(
            root: node,
            path: path,
            problemReporter: problemReporter) {
            guard let valueText = valueNode.text else {
                report(XMLSchemaProblem(message: "No value for key \(key).\(valueKey)"))
                return nil
            }
            switch valueKey {
            case "NSStringLocalizedFormatKey":
                guard valueNode.name == "string" else {
                    report(XMLSchemaProblem(message: "Unexpected value for key \(valueKey): \(valueNode.name)"))
                    return nil
                }
                maybeFormatKey = valueText
                maybeOrderedRuleKeys = Expressions.stringsdictArgumentRegex
                    .lo_matches(in: valueText)
                    .compactMap { $0.lo_getGroup(in: valueText, named: "name") }
            default:
                guard let variable = StringsdictRule(
                    key: valueKey,
                    node: valueNode,
                    path: path,
                    problemReporter: problemReporter) else {
                    return nil
                }
                rules[valueKey] = variable
            }
        }

        guard let formatKey = maybeFormatKey else {
            report(XMLSchemaProblem(message: "\(key) contains no value for NSStringLocalizedFormatKey"))
            return nil
        }
        if maybeOrderedRuleKeys == nil {
            report(
                StringsdictEntryHasNoVariables(
                    key: key,
                    formatKey: formatKey))
        }
        var hasAllVariables = true
        for variableKey in maybeOrderedRuleKeys ?? [] where rules[variableKey] == nil {
            report(
                StringsdictEntryHasMissingVariable(
                    key: key,
                    variable: variableKey,
                    ruleKey: "format key"))
            hasAllVariables = false
        }

        guard hasAllVariables else {
            return nil
        }

        self.key = key
        self.formatKey = LexedStringsdictString(string: formatKey)
        self.rules = rules

        validateRuleVariables(path: path, problemReporter: problemReporter)
    }
}
