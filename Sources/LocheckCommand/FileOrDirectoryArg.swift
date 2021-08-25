//
//  FileArg.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import ArgumentParser
import Files
import Foundation

/**
 ArgumentParser-compatible representation of a file. You must call `validate()` on it
 in your command's `validate()` method.
 */
class FileOrDirectoryArg {
    let argument: String

    /// Creates a new instance of this type from a command-line-specified
    /// argument.
    required init?(argument: String) {
        self.argument = argument
    }

    func validate(ext: String? = nil) throws {
        guard FileManager.default.fileExists(atPath: argument) else {
            throw ValidationError("File does not exist at \(argument)")
        }
        if let ext = ext, !argument.hasSuffix(".\(ext)") {
            throw ValidationError("That's not a .\(ext) file")
        }
    }
}

class FileArg: FileOrDirectoryArg, ExpressibleByArgument {
    /// The description of this instance to show as a default value in a
    /// command-line tool's help screen.
    let defaultValueDescription = "/path/to/Localizable.strings"

    override func validate(ext: String? = nil) throws {
        try super.validate(ext: ext)
        _ = try File(path: argument)
    }
}

class DirectoryArg: FileOrDirectoryArg, ExpressibleByArgument {
    /// The description of this instance to show as a default value in a
    /// command-line tool's help screen.
    let defaultValueDescription = "/path/to/a/directory"

    override func validate(ext: String? = nil) throws {
        try super.validate(ext: ext)
        _ = try Folder(path: argument)
    }
}
