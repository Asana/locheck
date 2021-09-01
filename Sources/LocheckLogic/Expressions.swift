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
    private static let stringPairExpression =
        "^(?<key>\(stringLiteralExpression)) = (?<value>\(stringLiteralExpression));$"
    static let stringPairRegex = try! NSRegularExpression(
        pattern: Expressions.stringPairExpression,
        options: .anchorsMatchLines)

    // MARK: Arguments

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

    // https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265
    private static let specifiers: [String] = [
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
    private static let specifierExpression = specifiers.joined(separator: "|")

    // Technically length modifiers are invalid for @ and potentially some others, but in practice
    // it probably doesn't matter.
    private static let nativeArgumentExpression =
        "%((?<position>\\d+)\\$)?(?<specifier>(\(lengthExpression))?(\(specifierExpression)))"
    static let nativeArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.nativeArgumentExpression,
        options: [])

    private static let stringsdictArgumentExpression = #"%#@(?<name>.+?)@"#
    static let stringsdictArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.stringsdictArgumentExpression,
        options: [])

    private static let phraseArgumentExpression = #"\{(?<name>\w+?)\}"#
    static let phraseArgumentRegex = try! NSRegularExpression(
        pattern: Expressions.phraseArgumentExpression,
        options: [])
}
