import ArgumentParser
import Files
import Foundation

struct FileArg: ExpressibleByArgument {
  let argument: String

  /// Creates a new instance of this type from a command-line-specified
  /// argument.
  init?(argument: String) {
    self.argument = argument
  }

  /// The description of this instance to show as a default value in a
  /// command-line tool's help screen.
  let defaultValueDescription = "/path/to/Localizable.strings"

  func validate(ext: String? = nil) throws {
    guard FileManager.default.fileExists(atPath: argument) else {
      throw ValidationError("File does not exist at \(argument)")
    }
    if let ext = ext, !argument.hasSuffix(".\(ext)") {
      throw ValidationError("That's not a .\(ext) file")
    }
  }
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
    for file in secondary {
      validateStrings(primary: try! File(path: primary.argument), secondary: try! File(path: file.argument))
    }
  }
}

struct Stringsdict: ParsableCommand {
  @Argument(help: "An authoritative .stringsdict file")
  private var primary: FileArg

  @Argument(help: "Non-authoritative .stringsdict files that need to be validated")
  private var secondary: [FileArg]

  func validate() throws {
    try primary.validate(ext: "stringsdict")
    try secondary.forEach { try $0.validate(ext: "stringsdict") }
  }

  func run() {
    print("STRINGSDICT!")
  }
}

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
    print("LPROJ!")
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

   var primaryLproj: LprojFiles!
   var secondaryLproj = [LprojFiles]()

    for folder in try! Folder(path: directory.argument).subfolders {
      if folder.extension != "lproj" { continue }
      if folder.name == "\(primary).lproj" {
        primaryLproj = LprojFiles(folder: folder)
      } else {
        secondaryLproj.append(LprojFiles(folder: folder))
      }
    }

    guard let primaryLproj = primaryLproj else {
      return // caught by validation already
    }

    print("Source of truth: \(primaryLproj.path)")
    print("Translations to check: \(secondaryLproj.count)")

    for secondary in secondaryLproj {
      validateLproj(primary: primaryLproj, secondary: secondary)
    }

    print("Finished validating")
  }
}

struct Locheck: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Validate your Xcode localization files",
    subcommands: [Strings.self, Stringsdict.self, Lproj.self, Discover.self])
}

Locheck.main()
