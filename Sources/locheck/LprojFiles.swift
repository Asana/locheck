//
//  File.swift
//
//
//  Created by Steve Landey on 8/18/21.
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
