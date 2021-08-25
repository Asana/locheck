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

struct Locheck: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: """
        Validate your Xcode localization files. Currently only works on .strings. The different
        commands have different amounts of automation. `discover` operates on a directory of
        .lproj files, `lproj` operates on specific .lproj files, and `strings` operates on
        specific .strings files.
        """,
        subcommands: [Discover.self, Lproj.self, Strings.self /* ,  Stringsdict.self */ ])
}

private func withProblemReporter(_ block: (ProblemReporter) -> Void) {
    let problemReporter = ProblemReporter()
    block(problemReporter)
    if problemReporter.hasError {
        print("Errors found")
        Darwin.exit(1)
    }
    print("Finished validating")
}

struct Strings: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Directly compare .strings files")

    @Argument(help: "An authoritative .strings file")
    private var base: FileArg

    @Argument(help: "Non-authoritative .strings files that need to be validated")
    private var translation: [FileArg]

    func validate() throws {
        try base.validate(ext: "strings")
        try translation.forEach { try $0.validate(ext: "strings") }
    }

    func run() {
        withProblemReporter { problemReporter in
            for file in translation {
                let translationFile = try! File(path: file.argument)
                parseAndValidateStrings(
                    base: try! File(path: base.argument),
                    translation: translationFile,
                    translationLanguageName: translationFile.nameExcludingExtension,
                    problemReporter: problemReporter)
            }
        }
    }
}

struct Lproj: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compare the contents of multiple .lproj files")

    @Argument(help: "An authoritative .lproj directory")
    private var base: FileArg

    @Argument(help: "Non-authoritative .lproj directories that need to be validated")
    private var translation: [FileArg]

    func validate() throws {
        try base.validate(ext: "lproj")
        try translation.forEach { try $0.validate(ext: "lproj") }
    }

    func run() {
        print("Validating \(translation.count) lproj files against \(try! Folder(path: base.argument).name)")

        withProblemReporter { problemReporter in
            for translation in translation {
                validateLproj(
                    base: LprojFiles(folder: try! Folder(path: base.argument)),
                    translation: LprojFiles(folder: try! Folder(path: translation.argument)),
                    problemReporter: problemReporter)
            }
        }
    }
}

struct Discover: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Automatically find .lproj files within a directory and compare them")

    @Option(help: "The authoritative language. Defaults to 'en'.")
    private var base = "en"

    @Argument(help: "A directory full of .lproj files, with one of them being authoritative.")
    private var directories: [FileArg]

    func validate() throws {
        for directory in directories {
            try directory.validate()

            var hasPrimary = false
            var hasSecondary = false

            for folder in try! Folder(path: directory.argument).subfolders {
                if folder.extension != "lproj" { continue }
                if folder.name == "\(base).lproj" { hasPrimary = true } else { hasSecondary = true }
            }

            if !hasPrimary {
                throw ValidationError("Can't find \(base).lproj in \(directory.argument)")
            }
            if !hasSecondary {
                throw ValidationError("Can't find any translation .lproj folders in in \(directory.argument)")
            }
        }
    }

    func run() {
        for directory in directories {
            print("Discovering .lproj files in \(directory.argument)")

            var maybePrimaryLproj: LprojFiles!
            var translationLproj = [LprojFiles]()

            for folder in try! Folder(path: directory.argument).subfolders {
                if folder.extension != "lproj" { continue }
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

            withProblemReporter { problemReporter in
                for translation in translationLproj {
                    validateLproj(base: baseLproj, translation: translation, problemReporter: problemReporter)
                }
            }
        }
    }
}

// We have an internal task tracking this functionality.
// struct Stringsdict: ParsableCommand {
//  @Argument(help: "An authoritative .stringsdict file")
//  private var base: FileArg
//
//  @Argument(help: "Non-authoritative .stringsdict files that need to be validated")
//  private var translation: [FileArg]
//
//  func validate() throws {
//    try base.validate(ext: "stringsdict")
//    try translation.forEach { try $0.validate(ext: "stringsdict") }
//  }
//
//  func run() {
//    print("STRINGSDICT!")
//  }
// }

Locheck.main()
