import ArgumentParser
import Darwin
import Files
import Foundation
import LocheckLogic

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
    @Argument(help: "An authoritative .strings file")
    private var primary: FileArg

    @Argument(help: "Non-authoritative .strings files that need to be validated")
    private var secondary: [FileArg]

    func validate() throws {
        try primary.validate(ext: "strings")
        try secondary.forEach { try $0.validate(ext: "strings") }
    }

    func run() {
        withProblemReporter { problemReporter in
            for file in secondary {
                let secondaryFile = try! File(path: file.argument)
                parseAndValidateStrings(
                    primary: try! File(path: primary.argument),
                    secondary: secondaryFile,
                    secondaryName: secondaryFile.nameExcludingExtension,
                    problemReporter: problemReporter)
            }
        }
    }
}

// We have an internal task tracking this functionality.
// struct Stringsdict: ParsableCommand {
//  @Argument(help: "An authoritative .stringsdict file")
//  private var primary: FileArg
//
//  @Argument(help: "Non-authoritative .stringsdict files that need to be validated")
//  private var secondary: [FileArg]
//
//  func validate() throws {
//    try primary.validate(ext: "stringsdict")
//    try secondary.forEach { try $0.validate(ext: "stringsdict") }
//  }
//
//  func run() {
//    print("STRINGSDICT!")
//  }
// }

struct Lproj: ParsableCommand {
    @Argument(help: "An authoritative .lproj directory")
    private var primary: FileArg

    @Argument(help: "Non-authoritative .lproj directories that need to be validated")
    private var secondary: [FileArg]

    func validate() throws {
        try primary.validate(ext: "lproj")
        try secondary.forEach { try $0.validate(ext: "lproj") }
    }

    func run() {
        print("Validating \(secondary.count) lproj files against \(try! Folder(path: primary.argument).name)")

        withProblemReporter { problemReporter in
            for secondary in secondary {
                validateLproj(
                    primary: LprojFiles(folder: try! Folder(path: primary.argument)),
                    secondary: LprojFiles(folder: try! Folder(path: secondary.argument)),
                    problemReporter: problemReporter)
            }
        }
    }
}

struct Discover: ParsableCommand {
    @Argument(help: "A directory full of .lproj files, with one of them being authoritative.")
    private var directory: FileArg

    @Argument(help: "The authoritative language. Defaults to 'en'.")
    private var primary = "en"

    func validate() throws {
        try directory.validate()

        var hasPrimary = false
        var hasSecondary = false

        for folder in try! Folder(path: directory.argument).subfolders {
            if folder.extension != "lproj" { continue }
            if folder.name == "\(primary).lproj" { hasPrimary = true } else { hasSecondary = true }
        }

        if !hasPrimary {
            throw ValidationError("Can't find \(primary).lproj in \(directory.argument)")
        }
        if !hasSecondary {
            throw ValidationError("Can't find any secondary .lproj folders in in \(directory.argument)")
        }
    }

    func run() {
        print("Discovering .lproj files in \(directory.argument)")

        var maybePrimaryLproj: LprojFiles!
        var secondaryLproj = [LprojFiles]()

        for folder in try! Folder(path: directory.argument).subfolders {
            if folder.extension != "lproj" { continue }
            if folder.name == "\(primary).lproj" {
                maybePrimaryLproj = LprojFiles(folder: folder)
            } else {
                secondaryLproj.append(LprojFiles(folder: folder))
            }
        }

        guard let primaryLproj = maybePrimaryLproj else {
            return // caught by validation already
        }

        print("Source of truth: \(primaryLproj.path)")
        print("Translations to check: \(secondaryLproj.count)")

        withProblemReporter { problemReporter in
            for secondary in secondaryLproj {
                validateLproj(primary: primaryLproj, secondary: secondary, problemReporter: problemReporter)
            }
        }
    }
}

struct Locheck: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: """
        Validate your Xcode localization files. Currently only works on .strings. The different
        commands have different amounts of automation. `discover` operates on a directory of
        .lproj files, `lproj` operates on specific .lproj files, and `strings` operates on\
        specific .strings files.
        """,
        subcommands: [Discover.self, Lproj.self, Strings.self /* ,  Stringsdict.self */ ])
}

Locheck.main()
