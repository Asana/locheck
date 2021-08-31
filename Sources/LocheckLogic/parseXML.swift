//
//  parseXML.swift
//
//
//  Created by Steve Landey on 8/31/21.
//

import Files
import Foundation
import SwiftyXMLParser

func parseXML(file: File, problemReporter: ProblemReporter) -> XML.Accessor? {
    do {
        return XML.parse(try file.read())
    } catch {
        problemReporter.report(
            XMLErrorProblem(message: error.localizedDescription),
            path: file.path,
            lineNumber: nil)
        return nil
    }
}
