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
        Validate your Xcode localization files. The different commands have
        different amounts of automation. `discover` operates on a directory of
        .lproj files, `lproj` operates on specific .lproj files, and `strings`
        operates on specific .strings files.
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

private func withProblemReporter(
    root: String,
    ignore: [String],
    ignoreWarnings: Bool,
    treatWarningsAsErrors: Bool,
    _ block: (ProblemReporter) -> Void) {
    let problemReporter = ProblemReporter(root: root, ignoredProblemIdentifiers: ignore, ignoreWarnings: ignoreWarnings)
    block(problemReporter)
    if problemReporter.hasError || (treatWarningsAsErrors && problemReporter.hasWarning) {
        print("Errors found")
        Darwin.exit(1)
    }
    print("Finished validating")
}

private let ignoreHelpText: ArgumentHelp = "Ignore a rule completely."

private let ignoreMissingHelpText: ArgumentHelp =
    "Ignore 'missing string' errors. Shorthand for '--ignore key_missing_from_base --ignore key_missing_from_translation'."

private let ignoreWarningsHelpText: ArgumentHelp = "Ignore all warning-level issues."

private let treatWarningsAsErrorsHelpText: ArgumentHelp =
    "Return a non-zero exit code if any warnings, not just errors, were encountered."

private protocol HasIgnoreWithShorthand {
    var ignore: [String] { get }
    var ignoreMissing: Bool { get }
}

private extension HasIgnoreWithShorthand {
    var ignoreWithShorthand: [String] {
        ignore + (ignoreMissing ? ["key_missing_from_base", "key_missing_from_translation"] : [])
    }
}

struct XCStrings: HasIgnoreWithShorthand, ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcstrings",
        abstract: "Directly compare .strings files")

    @Argument(help: "A list of .strings files, starting with the primary language")
    private var stringsFiles: [FileArg] = []

    @Option(help: ignoreHelpText)
    fileprivate var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    fileprivate var ignoreMissing = false

    @Flag(help: ignoreWarningsHelpText)
    fileprivate var ignoreWarnings = false

    @Flag(help: treatWarningsAsErrorsHelpText)
    fileprivate var treatWarningsAsErrors = false

    func validate() throws {
        try stringsFiles.forEach { try $0.validate(ext: "strings") }
    }

    func run() {
        withProblemReporter(
            root: "",
            ignore: ignoreWithShorthand,
            ignoreWarnings: ignoreWarnings,
            treatWarningsAsErrors: treatWarningsAsErrors) { problemReporter in
                let base = stringsFiles[0]
                let translationFiles = stringsFiles.dropFirst()
                for file in translationFiles {
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

struct AndroidStrings: HasIgnoreWithShorthand, ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "androidstrings",
        abstract: "Directly compare strings.xml files")

    @Argument(help: "A list of strings.xml files, starting with the primary language")
    private var stringsFiles: [FileArg]

    @Option(help: ignoreHelpText)
    fileprivate var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    fileprivate var ignoreMissing = false

    @Flag(help: ignoreWarningsHelpText)
    fileprivate var ignoreWarnings = false

    @Flag(help: treatWarningsAsErrorsHelpText)
    fileprivate var treatWarningsAsErrors = false

    func validate() throws {
        try stringsFiles.forEach { try $0.validate(ext: "xml") }
    }

    func run() {
        withProblemReporter(
            root: "",
            ignore: ignoreWithShorthand,
            ignoreWarnings: ignoreWarnings,
            treatWarningsAsErrors: treatWarningsAsErrors) { problemReporter in
                let baseFile = stringsFiles[0]
                let translationFiles = stringsFiles.dropFirst()
                if translationFiles.isEmpty {
                    // Just do what we can with the base language, i.e. validate plurals
                    _ = AndroidStringsFile(path: baseFile.argument, problemReporter: problemReporter)
                }
                for file in translationFiles {
                    let translationFile = try! File(path: file.argument)
                    var translationLanguageName = translationFile.parent!.nameExcludingExtension
                    if translationLanguageName.hasPrefix("values-") {
                        translationLanguageName = String(translationLanguageName.dropFirst("values-".count))
                    }
                    parseAndValidateAndroidStrings(
                        base: try! File(path: baseFile.argument),
                        translation: translationFile,
                        translationLanguageName: translationLanguageName,
                        problemReporter: problemReporter)
                }
                problemReporter.printSummary()
            }
    }
}

struct Stringsdict: HasIgnoreWithShorthand, ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Directly compare .stringsdict files")

    @Argument(help: "A list of .stringsdict files, starting with the primary language")
    private var stringsdictFiles: [FileArg]

    @Option(help: ignoreHelpText)
    fileprivate var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    fileprivate var ignoreMissing = false

    @Flag(help: ignoreWarningsHelpText)
    fileprivate var ignoreWarnings = false

    @Flag(help: treatWarningsAsErrorsHelpText)
    fileprivate var treatWarningsAsErrors = false

    func validate() throws {
        try stringsdictFiles.forEach { try $0.validate(ext: "stringsdict") }
    }

    func run() {
        withProblemReporter(
            root: "",
            ignore: ignoreWithShorthand,
            ignoreWarnings: ignoreWarnings,
            treatWarningsAsErrors: treatWarningsAsErrors) { problemReporter in
                let baseFile = stringsdictFiles[0]
                let translationFiles = stringsdictFiles.dropFirst()
                // Just do what we can with the base language, i.e. validate plurals
                if translationFiles.isEmpty, let stringsdictFile = StringsdictFile(
                    path: baseFile.argument,
                    problemReporter: problemReporter) {
                    stringsdictFile.entries
                        .forEach { _ = $0.getCanonicalArgumentList(problemReporter: problemReporter) }
                }
                for file in translationFiles {
                    let translationFile = try! File(path: file.argument)
                    parseAndValidateStringsdict(
                        base: try! File(path: baseFile.argument),
                        translation: translationFile,
                        translationLanguageName: translationFile.nameExcludingExtension,
                        problemReporter: problemReporter)
                }
                problemReporter.printSummary()
            }
    }
}

struct Lproj: HasIgnoreWithShorthand, ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compare the contents of multiple .lproj files")

    @Argument(help: "A list of .lproj files, starting with the primary language")
    private var lprojFiles: [DirectoryArg]

    @Option(help: ignoreHelpText)
    fileprivate var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    fileprivate var ignoreMissing = false

    @Flag(help: ignoreWarningsHelpText)
    fileprivate var ignoreWarnings = false

    @Flag(help: treatWarningsAsErrorsHelpText)
    fileprivate var treatWarningsAsErrors = false

    func validate() throws {
        try lprojFiles.forEach { try $0.validate(ext: "lproj") }
    }

    func run() {
        let baseFile = lprojFiles[0]
        let translationFiles = lprojFiles.dropFirst()
        if !translationFiles.isEmpty {
            print(
                "Validating \(translationFiles.count) lproj files against \(try! Folder(path: baseFile.argument).name)")
        }

        withProblemReporter(
            root: "",
            ignore: ignoreWithShorthand,
            ignoreWarnings: ignoreWarnings,
            treatWarningsAsErrors: treatWarningsAsErrors) { problemReporter in
                // Same as in DiscoverLproj command below
                if translationFiles.isEmpty {
                    // Just do what we can with the base language, i.e. validate plurals
                    let lprojFiles = LprojFiles(folder: try! Folder(path: baseFile.argument))
                    lprojFiles.validateInternally(problemReporter: problemReporter)
                }
                for translation in translationFiles {
                    validateLproj(
                        base: LprojFiles(folder: try! Folder(path: baseFile.argument)),
                        translation: LprojFiles(folder: try! Folder(path: translation.argument)),
                        problemReporter: problemReporter)
                }
                problemReporter.printSummary()
            }
    }
}

struct DiscoverLproj: HasIgnoreWithShorthand, ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discoverlproj",
        abstract: "Automatically find .lproj files within a directory and compare them")

    @Option(help: "The authoritative language. Defaults to 'en'. ")
    private var base = "en"

    @Argument(
        help: "One or more directories full of .lproj files, with one of them being authoritative (defined by --base).")
    private var directories: [DirectoryArg]

    @Option(help: ignoreHelpText)
    fileprivate var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    fileprivate var ignoreMissing = false

    @Flag(help: ignoreWarningsHelpText)
    fileprivate var ignoreWarnings = false

    @Flag(help: treatWarningsAsErrorsHelpText)
    fileprivate var treatWarningsAsErrors = false

    func validate() throws {
        for directory in directories {
            try directory.validate()

            let hasBase = try! Folder(path: directory.argument).subfolders.contains { $0.name == "\(base).lproj" }

            if !hasBase {
                throw ValidationError(
                    "Can't find \(base).lproj in \(directory.argument). Do you need to specify --base?")
            }
        }
    }

    func run() {
        for directory in directories {
            print("Discovering .lproj files in \(directory.argument) with \(base) as the base")

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

            withProblemReporter(
                root: directory.argument,
                ignore: ignoreWithShorthand,
                ignoreWarnings: ignoreWarnings,
                treatWarningsAsErrors: treatWarningsAsErrors) { problemReporter in
                    // Same as in Lproj command above
                    if translationLproj.isEmpty {
                        // Just do what we can with the base language, i.e. validate plurals
                        baseLproj.validateInternally(problemReporter: problemReporter)
                    }

                    for translation in translationLproj {
                        validateLproj(base: baseLproj, translation: translation, problemReporter: problemReporter)
                    }
                    problemReporter.printSummary()
                }
        }
    }
}

struct DiscoverValues: HasIgnoreWithShorthand, ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "discovervalues",
        abstract: "Automatically find values/ directories files within a directory and compare their strings.xml files")

    @Argument(help: "One or more directories full of values[-*]/ directories, with one of them being authoritative.")
    private var directories: [DirectoryArg]

    @Option(help: ignoreHelpText)
    fileprivate var ignore = [String]()

    @Flag(help: ignoreMissingHelpText)
    fileprivate var ignoreMissing = false

    @Flag(help: ignoreWarningsHelpText)
    fileprivate var ignoreWarnings = false

    @Flag(help: treatWarningsAsErrorsHelpText)
    fileprivate var treatWarningsAsErrors = false

    func validate() throws {
        for directory in directories {
            try directory.validate()

            var hasBase = false
            // It's OK if there are no translations, we can validate just one file for consistency

            for folder in try Folder(path: directory.argument).subfolders where folder.name.hasPrefix("values") {
                if folder.name == "values" {
                    hasBase = true
                }

                if folder.name == "values" {
                    // base localization must have strings.xml, otherwise it's fine
                    _ = try folder.file(named: "strings.xml")
                }
            }

            if !hasBase {
                throw ValidationError("Can't find values/ directory in \(directory.argument)")
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
                } else if folder.name.hasPrefix("values-"), let stringsFile = try? folder.file(named: "strings.xml") {
                    translationValues.append(stringsFile)
                }
            }

            guard let primaryValues = maybePrimaryValues else {
                return // caught by validation already
            }

            print("Source of truth: \(primaryValues.path)")
            print("Translations to check: \(translationValues.count)")

            withProblemReporter(
                root: directory.argument,
                ignore: ignoreWithShorthand,
                ignoreWarnings: ignoreWarnings,
                treatWarningsAsErrors: treatWarningsAsErrors) { problemReporter in
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
