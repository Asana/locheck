//
//  lproj.swift
//
//
//  Created by Steve Landey on 8/17/21.
//

import Files
import Foundation

struct LprojFiles {
  let name: String
  let path: String
  let strings: [File]
  let stringsdict: [File]

  init(folder: Folder) {
    name = folder.nameExcludingExtension
    path = folder.path
    var strings = [File]()
    var stringsdict = [File]()

    for file in folder.files {
      switch file.extension {
      case "strings": strings.append(file)
      case "stringsdict": stringsdict.append(file)
      default: break
      }
    }

    self.strings = strings
    self.stringsdict = stringsdict
  }
}

func validateLproj(primary: LprojFiles, secondary: LprojFiles) {
  for stringsFile in primary.strings {
    guard let secondaryStringsFile = secondary.strings.first(where: { $0.name == stringsFile.name }) else {
      print("error: \(stringsFile.name) missing from translation \(secondary.name)")
      continue
    }
    validateStrings(primary: stringsFile, secondary: secondaryStringsFile, secondaryName: secondary.name)
  }

  for stringsdictFile in primary.stringsdict {
    guard let secondaryStringsdictFile = secondary.stringsdict.first(where: { $0.name == stringsdictFile.name }) else {
      print("error: \(stringsdictFile.name) missing from translation \(secondary.name)")
      continue
    }
    validateStringsdict(primary: stringsdictFile, secondary: secondaryStringsdictFile)
  }
}
