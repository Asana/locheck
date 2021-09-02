//
//  main.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import ArgumentParser
import Darwin
import Files
import Foundation
import LocheckLogic

let version = "0.9.2"

struct Locheck: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: """
        Validate your Xcode localization files. Currently only works on .strings. The different
        commands have different amounts of automation. `discover` operates on a directory of
        .lproj files, `lproj` operates on specific .lproj files, and `strings` operates on
        specific .strings files.
        """,
        subcommands: [
            DiscoverLproj.self,
            DiscoverValues.self,
            Lproj.self,
            XCStrings.self,
            Stringsdict.self,
            AndroidStrings.self,
            Version.self,
        ])
}

private func withProblemReporter(ignore: [String], _ block: (ProblemReporter) -> Void) {
    let problemReporter = ProblemReporter(ignoredProblemIdentifiers: ignore)
    block(problemReporter)
    if problemReporter.hasError {
        print("Errors found")
        Darwin.exit(1)
    }
    print("Finished validating")
}

private let ignoreHelpText: ArgumentHelp =
    "Ignore a rule completely."

private let ignoreMissingHelpText: ArgumentHelp =
    "Ignore 'missing string' errors. Shorthand for '--ignore key_missing_from_base --ignore key_missing_from_translation'."

struct XCStrings: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcstrings",
        abstract: "Directly compare .strings files")

    @Argument(help: "An authoritative .strings file")
    private var base: FileArg

    @Argument(help: "Non-authoritative .strings files that need to be validated")
    private var translation: [FileArg]

    @Option(help: ignoreHelpText)
    private var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    private var ignoreMissing = false

    private var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }

    func validate() throws {
        try base.validate(ext: "strings")
        try translation.forEach { try $0.validate(ext: "strings") }
    }

    func run() {
        withProblemReporter(ignore: ignoreWithShorthand) { problemReporter in
            for file in translation {
                let translationFile = try! File(path: file.argument)
                parseAndValidateXCStrings(
                    base: try! File(path: base.argument),
                    translation: translationFile,
                    translationLanguageName: translationFile.nameExcludingExtension,
                    problemReporter: problemReporter)
            }
            problemReporter.printSummary()
        }
    }
}

struct AndroidStrings: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "androidstrings",
        abstract: "Directly compare strings.xml files")

    @Argument(help: "An authoritative strings.xml file")
    private var base: FileArg

    @Argument(help: "Non-authoritative strings.xml files that need to be validated")
    private var translation: [FileArg]

    @Option(help: ignoreHelpText)
    private var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    private var ignoreMissing = false

    private var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }

    func validate() throws {
        try base.validate(ext: "xml")
        try translation.forEach { try $0.validate(ext: "xml") }
    }

    func run() {
        withProblemReporter(ignore: ignoreWithShorthand) { problemReporter in
            for file in translation {
                let translationFile = try! File(path: file.argument)
                var translationLanguageName = translationFile.parent!.nameExcludingExtension
                if translationLanguageName.hasPrefix("values-") {
                    translationLanguageName = String(translationLanguageName.dropFirst("values-".count))
                }
                parseAndValidateAndroidStrings(
                    base: try! File(path: base.argument),
                    translation: translationFile,
                    translationLanguageName: translationLanguageName,
                    problemReporter: problemReporter)
            }
            problemReporter.printSummary()
        }
    }
}

struct Stringsdict: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Directly compare .stringsdict files")

    @Argument(help: "An authoritative .stringsdict file")
    private var base: FileArg

    @Argument(help: "Non-authoritative .stringsdict files that need to be validated")
    private var translation: [FileArg]

    @Option(help: ignoreHelpText)
    private var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    private var ignoreMissing = false

    private var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }

    func validate() throws {
        try base.validate(ext: "stringsdict")
        try translation.forEach { try $0.validate(ext: "stringsdict") }
    }

    func run() {
        withProblemReporter(ignore: ignoreWithShorthand) { problemReporter in
            for file in translation {
                let translationFile = try! File(path: file.argument)
                parseAndValidateStringsdict(
                    base: try! File(path: base.argument),
                    translation: translationFile,
                    translationLanguageName: translationFile.nameExcludingExtension,
                    problemReporter: problemReporter)
            }
            problemReporter.printSummary()
        }
    }
}

struct Lproj: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compare the contents of multiple .lproj files")

    @Argument(help: "An authoritative .lproj directory")
    private var base: DirectoryArg

    @Argument(help: "Non-authoritative .lproj directories that need to be validated")
    private var translation: [DirectoryArg]

    @Option(help: ignoreHelpText)
    private var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    private var ignoreMissing = false

    private var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }

    func validate() throws {
        try base.validate(ext: "lproj")
        try translation.forEach { try $0.validate(ext: "lproj") }
    }

    func run() {
        print("Validating \(translation.count) lproj files against \(try! Folder(path: base.argument).name)")

        withProblemReporter(ignore: ignoreWithShorthand) { problemReporter in
            for translation in translation {
                validateLproj(
                    base: LprojFiles(folder: try! Folder(path: base.argument)),
                    translation: LprojFiles(folder: try! Folder(path: translation.argument)),
                    problemReporter: problemReporter)
            }
            problemReporter.printSummary()
        }
    }
}

struct DiscoverLproj: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discoverlproj",
        abstract: "Automatically find .lproj files within a directory and compare them")

    @Option(help: "The authoritative language. Defaults to 'en'. ")
    private var base = "en"

    @Argument(
        help: "One or more directories full of .lproj files, with one of them being authoritative (defined by --base).")
    private var directories: [DirectoryArg]

    @Option(help: ignoreHelpText)
    private var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    private var ignoreMissing = false

    private var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }

    func validate() throws {
        for directory in directories {
            try directory.validate()

            var hasBase = false
            var hasTranslation = false

            for folder in try! Folder(path: directory.argument).subfolders where folder.extension == "lproj" {
                if folder.name == "\(base).lproj" {
                    hasBase = true
                } else {
                    hasTranslation = true
                }
            }

            if !hasBase {
                throw ValidationError("Can't find \(base).lproj or values/ directory in \(directory.argument)")
            }
            if !hasTranslation {
                throw ValidationError("Can't find any translation .lproj or values/ folders in \(directory.argument)")
            }
        }
    }

    func run() {
        for directory in directories {
            print("Discovering .lproj files in \(directory.argument)")

            var maybePrimaryLproj: LprojFiles!
            var translationLproj = [LprojFiles]()

            for folder in try! Folder(path: directory.argument).subfolders where folder.extension == "lproj" {
                if folder.name == "\(base).lproj" {
                    maybePrimaryLproj = LprojFiles(folder: folder)
                } else {
                    translationLproj.append(LprojFiles(folder: folder))
                }
            }

            guard let baseLproj = maybePrimaryLproj else {
                return // caught by validation already
            }

            print("Source of truth: \(baseLproj.path)")
            print("Translations to check: \(translationLproj.count)")

            withProblemReporter(ignore: ignoreWithShorthand) { problemReporter in
                for translation in translationLproj {
                    validateLproj(base: baseLproj, translation: translation, problemReporter: problemReporter)
                }
                problemReporter.printSummary()
            }
        }
    }
}

struct DiscoverValues: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discovervalues",
        abstract: "Automatically find values/ directories files within a directory and compare their strings.xml files")

    @Argument(help: "One or more directories full of values[-*]/ directories, with one of them being authoritative.")
    private var directories: [DirectoryArg]

    @Option(help: ignoreHelpText)
    private var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    private var ignoreMissing = false

    private var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }

    func validate() throws {
        for directory in directories {
            try directory.validate()

            var hasBase = false
            var hasTranslation = false

            for folder in try Folder(path: directory.argument).subfolders where folder.name.hasPrefix("values") {
                if folder.name == "values" {
                    hasBase = true
                } else {
                    hasTranslation = true
                }

                _ = try folder.file(named: "strings.xml") // make sure it exists
            }

            if !hasBase {
                throw ValidationError("Can't find values/ directory in \(directory.argument)")
            }
            if !hasTranslation {
                throw ValidationError("Can't find any values-*/ directories in \(directory.argument)")
            }
        }
    }

    func run() {
        for directory in directories {
            print("Discovering values[-*]/strings.xml files in \(directory.argument)")

            var maybePrimaryValues: File?
            var translationValues = [File]()

            for folder in try! Folder(path: directory.argument).subfolders where folder.name.hasPrefix("values") {
                if folder.name == "values" {
                    maybePrimaryValues = try! folder.file(named: "strings.xml")
                } else if folder.name.hasPrefix("values-") {
                    translationValues.append(try! folder.file(named: "strings.xml")) // validated earlier
                }
            }

            guard let primaryValues = maybePrimaryValues else {
                return // caught by validation already
            }

            print("Source of truth: \(primaryValues.path)")
            print("Translations to check: \(translationValues.count)")

            withProblemReporter(ignore: ignoreWithShorthand) { problemReporter in
                for translation in translationValues {
                    parseAndValidateAndroidStrings(
                        base: primaryValues,
                        translation: translation,
                        translationLanguageName: String(translation.parent!.name.dropFirst("values-".count)),
                        problemReporter: problemReporter)
                }
                problemReporter.printSummary()
            }
        }
    }
}

struct Version: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print the installed version of locheck to stdout")

    func run() {
        print(version)
    }
}

Locheck.main()
