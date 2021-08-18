//
//  File.swift
//
//
//  Created by Steve Landey on 8/18/21.
//

import Files
import Foundation

public struct LprojFiles {
  public let name: String
  public let path: String
  public let strings: [File]
  public let stringsdict: [File]

  public init(folder: Folder) {
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
