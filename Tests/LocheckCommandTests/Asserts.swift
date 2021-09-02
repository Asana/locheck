//
//  Asserts.swift
//
//
//  Created by Steve Landey on 9/1/21.
//

import Foundation
import XCTest

func CastAndAssertEqual<T: Equatable>(
    _ a: Any?,
    _ b: T,
    file: StaticString = #file,
    line: UInt = #line) {
    XCTAssertEqual(a as? T, b)
}
