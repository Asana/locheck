//
//  Problems.swift
//
//
//  Created by Steve Landey on 8/27/21.
//

import Foundation

struct LprojFileMissingFromTranslation: Problem, Equatable {
    var identifier: String { "lproj_file_missing_from_translation-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String { "\(key) missing from \(language)" }
}

struct StringHasDuplicateArguments: Problem, Equatable {
    var identifier: String { "string_has_duplicate_arguments-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String {
        "Some arguments appear more than once in this translation"
    }
}

struct StringHasExtraArguments: Problem, Equatable {
    var identifier: String { "string_has_extra_arguments-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String
    let args: [String]

    var message: String {
        "Translation includes arguments that don't exist in the source: \(args.joined(separator: ", "))"
    }
}

struct StringHasInvalidArgument: Problem, Equatable {
    var identifier: String { "string_has_invalid_argument-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String
    let argPosition: Int
    let baseArgSpecifier: String
    let argSpecifier: String

    var message: String {
        "Specifier for argument \(argPosition) does not match (should be \(baseArgSpecifier), is \(argSpecifier)"
    }
}

struct StringHasMissingArguments: Problem, Equatable {
    var identifier: String { "string_has_missing_arguments-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String
    let args: [String]

    var message: String { "Does not include argument(s) at \(args.joined(separator: ", "))" }
}

struct StringsKeyMissingFromTranslation: Problem, Equatable {
    var identifier: String { "strings_key_missing_from_translation-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String { "This string is missing from \(language)" }
}

struct StringsdictEntryContainsNoVariablesProblem: Problem, Equatable {
    var identifier: String { "stringsdict_entry_contains_no_variables-\(key)" }
    var severity: Severity { .warning }
    let key: String

    var message: String { "'\(key)' contains no variables" }
}

struct StringsdictEntryHasImplicitPosition: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_implicit_position-\(key)-\(position)-\(permutation)" }
    var severity: Severity { .warning }
    let key: String
    let position: Int
    let permutation: String

    var message: String {
        "Argument \(position) in permutation '\(permutation) of '\(key)' has an implicit position. Use an explicit position for safety."
    }
}

struct StringsdictEntryHasInvalidArgument: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_invalid_argument-\(key)-\(position)" }
    var severity: Severity { .error }
    let key: String
    let position: Int
    let baseSpecifier: String
    let translationSpecifier: String

    var message: String {
        "'\(key)' has the wrong specifier at position \(position). (Should be '\(baseSpecifier)', is '\(translationSpecifier)')"
    }
}

struct StringsdictEntryHasInvalidSpecifier: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_invalid_specifier-\(key)-\(position)-\(permutation1)-\(permutation2)" }
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

struct StringsdictEntryHasMissingVariable: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_missing_variable-\(variable)-\(key)" }
    var severity: Severity { .error }
    let key: String
    let variable: String
    let ruleKey: String

    var message: String {
        "Variable \(variable) does not exist in '\(key)' but is used in \(ruleKey)"
    }
}

struct StringsdictEntryHasNoVariables: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_no_variables-\(key)" }
    var severity: Severity { .error }
    let key: String
    let formatKey: String

    var message: String {
        "\(key) contains no variables in its format key: \(formatKey)"
    }
}

struct StringsdictEntryHasTooManyArguments: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_too_many_arguments-\(key)" }
    var severity: Severity { .error }
    let key: String
    let extraArgs: [String]

    var message: String {
        "'\(key)' has more arguments than the base language. Extra args: \(extraArgs.joined(separator: ", "))"
    }
}

struct StringsdictEntryHasUnusedArguments: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_unused_arguments-\(key)-\(positions)" }
    var severity: Severity { .warning }
    let key: String
    let positions: [Int]

    var message: String {
        let joinedString = positions.map { String($0 + 1) }.joined(separator: ", ")

        return "No permutation of '\(key)' use argument(s) at position \(joinedString)"
    }
}

struct StringsdictEntryHasUnverifiableArgument: Problem, Equatable {
    var identifier: String { "stringsdict_entry_has_unverifiable_argument-\(key)-\(position)" }
    var severity: Severity { .warning }
    let key: String
    let position: Int

    var message: String {
        "'\(key)' has an argument at position \(position), but the base translation does not, so we can't verify it."
    }
}

struct StringsdictEntryMissingArgument: Problem, Equatable {
    var identifier: String { "stringsdict_entry_missing_argument-\(key)-\(position)" }
    var severity: Severity { .warning }
    let key: String
    let position: Int

    var message: String { "'\(key)' does not use argument \(position)" }
}

struct StringsdictEntryMissingFormatSpecTypeProblem: Problem, Equatable {
    var identifier: String { "stringsdict_entry_missing_format_spec_type-\(key)" }
    var severity: Severity { .error }
    let key: String

    var message: String { "'\(key)' is missing NSStringFormatSpecTypeKey" }
}

struct StringsdictEntryMissingFormatValueTypeProblem: Problem, Equatable {
    var identifier: String { "stringsdict_entry_missing_format_spec_value-\(key)" }
    var severity: Severity { .error }
    let key: String

    var message: String { "'\(key)' is missing NSStringFormatValueTypeKey" }
}

struct StringsdictKeyMissingFromBase: Problem, Equatable {
    var identifier: String { "stringsdict_key_missing_from_base-\(key)" }
    var severity: Severity { .warning }
    let key: String

    var message: String { "'\(key)' is missing from the base translation" }
}

struct StringsdictKeyMissingFromTranslation: Problem, Equatable {
    var identifier: String { "stringsdict_key_missing_from_translation-\(language)-\(key)" }
    var severity: Severity { .warning }
    let key: String
    let language: String

    var message: String { "'\(key)' is missing from the the \(language) translation" }
}

struct XMLErrorProblem: Problem, Equatable {
    var identifier: String { "xml_error" }
    var severity: Severity { .error }
    let message: String
}

struct XMLSchemaProblem: Problem, Equatable {
    var identifier: String { "xml_schema_error" }
    var severity: Severity { .error }
    let message: String
}
