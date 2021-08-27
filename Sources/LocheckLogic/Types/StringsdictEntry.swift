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
    let orderedRuleKeys: [String] // derived from formatKey

    var orderedRules: [StringsdictRule] {
        orderedRuleKeys.map { rules[$0]! }
    }

    func validateRuleVariables(path: String, problemReporter: ProblemReporter) {
        let checkRule = { (ruleKey: String, variables: [String]) -> Void in
            for variable in variables {
                if rules[variable] == nil {
                    // lineNumber is zero because we don't have it from SwiftyXMLParser.
                    problemReporter.report(
                        .error,
                        path: path,
                        lineNumber: 0,
                        message: "Variable \(variable) does not exist in '\(key)' but is used in \(ruleKey)")
                }
            }
        }

        checkRule("the format key", formatKey.variables)
        for rule in rules.values.sorted(by: { $0.key < $1.key }) {
            for (alternativeKey, alternative) in rule.alternatives {
                checkRule("'\(rule.key)'.\(alternativeKey)", alternative.variables)
            }
        }
    }

    var canonicalArgumentList: [FormatArgument] {
        
    }

    /**
     Generate every possible permutation of this string. For example, if your format key is
     `%#@abc@` and you have a rule `abc` with variants `one="xxx"` and `other="yyy"`, this
     getter will return `["xxx", "yyy"]`.

     In order to be comprehensive, it needs to recursively expand every rule, including nested
     rules.

     Example input:
     ```
     sandwich:
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
        let reportError = { (message: String) -> Void in
            // lineNumber is zero because we don't have it from SwiftyXMLParser.
            problemReporter.report(.error, path: path, lineNumber: 0, message: message)
        }

        var maybeFormatKey: String?
        var rules = [String: StringsdictRule]()
        var maybeOrderedRuleKeys: [String]?

        for (valueKey, valueNode) in readPlistDict(
            root: node,
            path: path,
            problemReporter: problemReporter) {
            guard let valueText = valueNode.text else {
                reportError("No value for key \(key).\(valueKey)")
                return nil
            }
            switch valueKey {
            case "NSStringLocalizedFormatKey":
                guard valueNode.name == "string" else {
                    reportError("Unexpected value for key \(valueKey): \(valueNode.name)")
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

        if maybeFormatKey == nil {
            reportError("\(key) contains no value for NSStringLocalizedFormatKey")
        }
        if maybeOrderedRuleKeys == nil {
            reportError("\(key) contains no variables in its format key: \(maybeFormatKey ?? "<unknown>")")
        }
        var hasAllVariables = true
        for variableKey in maybeOrderedRuleKeys ?? [] where rules[variableKey] == nil {
            reportError("Rule \(variableKey) is not defined in \(key)")
            hasAllVariables = false
        }

        guard let formatKey = maybeFormatKey, let orderedRuleKeys = maybeOrderedRuleKeys, hasAllVariables else {
            return nil
        }

        self.key = key
        self.formatKey = LexedStringsdictString(string: formatKey)
        self.orderedRuleKeys = orderedRuleKeys
        self.rules = rules

        validateRuleVariables(path: path, problemReporter: problemReporter)
    }
}
