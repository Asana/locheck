//
//  Problems.swift
//
//
//  Created by Steve Landey on 8/27/21.
//

import Foundation

protocol StringsdictProblem: SummarizableProblem {
    var key: String { get }
}

protocol StringsProblem: SummarizableProblem {
    var key: String { get }
}

struct DuplicateEntries: Problem, Equatable {
    var kindIdentifier: String { "duplicate_entries" }
    var uniquifyingInformation: String { "\(context ?? "<root>")-\(name)" }
    var severity: Severity { .error }
    let context: String?
    let name: String

    var message: String {
        if let context = context {
            return "'\(name)' appears twice in '\(context)'"
        } else {
            return "'\(name)' appears twice"
        }
    }
}

struct KeyMissingFromBase: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "key_missing_from_base" }
    var uniquifyingInformation: String { "\(key)" }
    var severity: Severity { .warning }
    let key: String

    var message: String { "'\(key)' is missing from the base translation" }
}

struct KeyMissingFromTranslation: Problem, StringsProblem, Equatable {
    var kindIdentifier: String { "key_missing_from_translation" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String { "'\(key)' is missing from \(language)" }
}

struct LprojFileMissingFromTranslation: Problem, Equatable {
    var kindIdentifier: String { "lproj_file_missing_from_translation" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String { "\(key) missing from \(language)" }
}

struct PhraseHasMissingArguments: Problem, StringsProblem, Equatable {
    var kindIdentifier: String { "phrase_has_missing_arguments" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String
    let args: [String]

    var message: String { "Does not include argument(s): \(args.joined(separator: ", "))" }
}

struct StringHasDuplicateArguments: Problem, StringsProblem, Equatable {
    var kindIdentifier: String { "string_has_duplicate_arguments" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String {
        "Some arguments appear more than once in this translation"
    }
}

struct StringHasExtraArguments: Problem, StringsProblem, Equatable {
    var kindIdentifier: String { "string_has_extra_arguments" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String
    let args: [String]

    var message: String {
        "Translation includes arguments that don't exist in the source: \(args.joined(separator: ", "))"
    }
}

struct StringHasInvalidArgument: Problem, StringsProblem, Equatable {
    var kindIdentifier: String { "string_has_invalid_argument" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .error }
    let key: String
    let language: String
    let argPosition: Int
    let baseArgSpecifier: String
    let argSpecifier: String

    var message: String {
        "Specifier for argument \(argPosition) does not match (should be \(baseArgSpecifier), is \(argSpecifier))"
    }
}

struct StringHasMissingArguments: Problem, StringsProblem, Equatable {
    var kindIdentifier: String { "string_has_missing_arguments" }
    var uniquifyingInformation: String { "\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String
    let args: [String]

    var message: String { "'\(key)' does not include argument(s) at \(args.joined(separator: ", "))" }
}

struct StringsdictEntryContainsNoVariablesProblem: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_contains_no_variables" }
    var uniquifyingInformation: String { "\(key)" }
    var severity: Severity { .warning }
    let key: String

    var message: String { "'\(key)' contains no variables" }
}

struct StringsdictEntryHasImplicitPosition: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_implicit_position" }
    var uniquifyingInformation: String { "\(key)-\(position)-\(permutation)" }
    // We have code to detect this, but without a way of disabling it per-project yet, it's not reported.
    var severity: Severity { .ignored }
    let key: String
    let position: Int
    let permutation: String

    var message: String {
        "Argument \(position) in permutation '\(permutation) of '\(key)' has an implicit position. Use an explicit position for safety."
    }
}

struct StringsdictEntryHasInvalidArgument: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_invalid_argument" }
    var uniquifyingInformation: String { "\(key)-\(position)" }
    var severity: Severity { .error }
    let key: String
    let position: Int
    let baseSpecifier: String
    let translationSpecifier: String

    var message: String {
        "'\(key)' has the wrong specifier at position \(position). (Should be '\(baseSpecifier)', is '\(translationSpecifier)')"
    }
}

struct StringsdictEntryPermutationsHaveConflictingSpecifiers: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_permutations_have_conflicting_specifiers" }
    var uniquifyingInformation: String { "\(key)-\(position)-\(permutation1)-\(permutation2)" }
    var severity: Severity { .error }
    let key: String
    let position: Int
    let permutation1: String
    let permutation2: String
    let specifier1: String
    let specifier2: String

    var message: String {
        "Two permutations of '\(key)' contain different format specifiers at position \(position). '\(permutation1)' uses '\(specifier1)', and '\(permutation2)' uses '\(specifier2)'."
    }
}

struct StringsdictEntryHasMissingVariable: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_missing_variable" }
    var uniquifyingInformation: String { "\(variable)-\(key)" }
    var severity: Severity { .error }
    let key: String
    let variable: String
    let ruleKey: String

    var message: String {
        "Variable \(variable) does not exist in '\(key)' but is used in \(ruleKey)"
    }
}

struct StringsdictEntryHasNoVariables: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_no_variables-" }
    var uniquifyingInformation: String { "\(key)" }
    var severity: Severity { .error }
    let key: String
    let formatKey: String

    var message: String {
        "\(key) contains no variables in its format key: \(formatKey)"
    }
}

struct StringsdictEntryHasTooManyArguments: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_too_many_arguments" }
    var uniquifyingInformation: String { "\(key)" }
    var severity: Severity { .error }
    let key: String
    let extraArgs: [String]

    var message: String {
        "'\(key)' has more arguments than the base language. Extra args: \(extraArgs.joined(separator: ", "))"
    }
}

struct StringsdictEntryHasUnusedArguments: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_unused_arguments" }
    var uniquifyingInformation: String { "\(key)-\(positions)" }
    var severity: Severity { .warning }
    let key: String
    let positions: [Int]

    var message: String {
        let joinedString = positions.map { String($0 + 1) }.joined(separator: ", ")

        return "No permutation of '\(key)' use argument(s) at position \(joinedString)"
    }
}

struct StringsdictEntryHasUnverifiableArgument: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_has_unverifiable_argument" }
    var uniquifyingInformation: String { "\(key)-\(position)" }
    var severity: Severity { .warning }
    let key: String
    let position: Int

    var message: String {
        "'\(key)' has an argument at position \(position), but the base translation does not, so we can't verify it."
    }
}

struct StringsdictEntryMissingArgument: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_missing_argument" }
    var uniquifyingInformation: String { "\(key)-\(position)" }
    var severity: Severity { .warning }
    let key: String
    let position: Int

    var message: String { "'\(key)' does not use argument \(position)" }
}

struct StringsdictEntryMissingFormatSpecTypeProblem: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_missing_format_spec_type" }
    var uniquifyingInformation: String { "\(key)" }
    var severity: Severity { .error }
    let key: String

    var message: String { "'\(key)' is missing NSStringFormatSpecTypeKey" }
}

struct StringsdictEntryMissingFormatValueTypeProblem: Problem, StringsdictProblem, Equatable {
    var kindIdentifier: String { "stringsdict_entry_missing_format_spec_value" }
    var uniquifyingInformation: String { "\(key)" }
    var severity: Severity { .error }
    let key: String

    var message: String { "'\(key)' is missing NSStringFormatValueTypeKey" }
}

struct XMLErrorProblem: Problem, Equatable {
    var kindIdentifier: String { "xml_error" }
    var uniquifyingInformation: String { message }
    var severity: Severity { .error }
    let message: String
}

struct XMLSchemaProblem: Problem, Equatable {
    var kindIdentifier: String { "xml_schema_error" }
    var uniquifyingInformation: String { message }
    var severity: Severity { .error }
    let message: String
}
