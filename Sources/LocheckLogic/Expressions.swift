//
//  Expressions.swift
//
//
//  Created by Steve Landey on 8/19/21.
//

import Foundation

/**
 Collection of regular expression patterns
 */
struct Expressions {
    private init() {}

    // MARK: String literals

    // https://stackoverflow.com/a/37032779
    private static let stringLiteralExpression = #""[^"\\]*(\\.[^"\\]*)*""#
    private static let greedyBlockCommentExpression = #"/\\*.*\\*/"#
    private static let blockCommentExpression = #"/\\*.*?\\*/"#
    private static let commentExpression = #"//.*"#
    private static let stringPairExpression =
        "^(?:\\s*\(blockCommentExpression)\\s*)*(?<key>\(stringLiteralExpression)) *= *(?<value>\(stringLiteralExpression));(?:\\s*\(greedyBlockCommentExpression)\\s*|\\s*\(commentExpression))?$"
    static let stringPairRegex = try! NSRegularExpression(
        pattern: Expressions.stringPairExpression,
        options: .anchorsMatchLines)

    // MARK: - Shared

    // https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265
    private static let lengthModifiers: [String] = [
        "h",
        "hh",
        "l",
        "ll",
        "q",
        "L",
        "z",
        "t",
        "j",
    ]
    private static let lengthExpression = lengthModifiers.joined(separator: "|")

    // MARK: - iOS Format Specifiers

    // https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265
    private static let iosSpecifiers: [String] = [
        // omit %%, it doesn't affect interpolation
        "@",
        "d",
        "D",
        "u",
        "U",
        "x",
        "X",
        "o",
        "O",
        "f",
        "e",
        "E",
        "g",
        "G",
        "c",
        "C",
        "s",
        "S",
        "p",
        "a",
        "A",
        "F",
    ]
    private static let iosSpecifierExpression = iosSpecifiers.joined(separator: "|")

    // Technically length modifiers are invalid for @ and potentially some others, but in practice
    // it probably doesn't matter.
    private static let iosArgumentExpression =
        "%((?<position>\\d+)\\$)?(?<specifier>(\(lengthExpression))?(\(iosSpecifierExpression)))"
    static let iosArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.iosArgumentExpression,
        options: [])

    // MARK: - Android Format Specifiers

    // https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Formatter.html
    private static let androidSpecifiers: [String] = [
        // General
        "b", // boolean
        "B", // boolean (uppercase)
        "h", // hash code (hexadecimal)
        "H", // hash code (uppercase)
        "s", // string
        "S", // string (uppercase)

        // Character
        "c", // character
        "C", // character (uppercase)

        // Integral
        "d", // decimal integer
        "o", // octal integer
        "x", // hexadecimal integer
        "X", // hexadecimal integer (uppercase)

        // Floating Point
        "e", // scientific notation
        "E", // scientific notation (uppercase)
        "f", // decimal floating point
        "g", // general (uses e or f)
        "G", // general (uppercase)
        "a", // hexadecimal floating point
        "A", // hexadecimal floating point (uppercase)

        // Date/Time (prefix, followed by date/time conversion suffix)
        "t", // date/time
        "T", // date/time (uppercase)
    ]
    private static let androidSpecifierExpression = androidSpecifiers.joined(separator: "|")

    // Android/Java Formatter flags: '-', '+', ' ', '0', ',', '(', '#'
    // https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Formatter.html
    // Flags: '-' (left-justify), '+' (include sign), ' ' (space for positive),
    // '0' (zero-pad), ',' (grouping separator), '(' (negative in parens), '#' (alternate form)
    private static let androidFlagsExpression = "[-+0, (#]*"
    private static let androidWidthExpression = "\\d*"
    private static let androidPrecisionExpression = "(?:\\.\\d+)?"

    // Full format: %[argument_index$][flags][width][.precision]conversion
    private static let androidArgumentExpression =
        "%((?<position>\\d+)\\$)?(?<specifier>\(androidFlagsExpression)\(androidWidthExpression)\(androidPrecisionExpression)(\(androidSpecifierExpression)))"
    static let androidArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.androidArgumentExpression,
        options: [])

    // MARK: - Legacy (backward compatibility)

    static let nativeArgumentRegex = iosArgumentRegex

    // MARK: - Other

    private static let stringsdictArgumentExpression = #"%[0-9]*\$?#@(?<name>.+?)@"#
    static let stringsdictArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.stringsdictArgumentExpression,
        options: [])

    private static let phraseArgumentExpression = #"\{(?<name>\w+?)\}"#
    static let phraseArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.phraseArgumentExpression,
        options: [])
}
