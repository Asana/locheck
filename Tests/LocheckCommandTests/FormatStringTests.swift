//
//  FormatStringTests.swift
//
//
//  Created by Steve Landey on 9/1/21.
//

import Foundation
@testable import LocheckLogic
import XCTest

class FormatStringTests: XCTestCase {
    func testImplicitPositionCounterIgnoresExplicitPositions() {
        let formatString = FormatString(string: "%2$@ %@", path: "", line: 0)
        XCTAssertEqual(
            formatString.arguments,
            [
                FormatArgument(specifier: "@", position: 2, isPositionExplicit: true),
                FormatArgument(specifier: "@", position: 1, isPositionExplicit: false),
            ])
    }
}
