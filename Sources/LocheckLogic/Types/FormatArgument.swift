//
//  FormatArgument.swift
//
//
//  Created by Steve Landey on 8/27/21.
//

import Foundation

/// The contents of one "%d" or "%2$@" argument. (These would be
/// `FormatArgument(specifier: "d", position: <automatic>)` and
/// `FormatArgument(specifier: "@", position: 2)`, respectively.)
struct FormatArgument: Equatable, Hashable {
    let specifier: String
    let position: Int
    let isPositionExplicit: Bool
}

extension FormatArgument {
    /// Accept position as a string.
    init(specifier: String, positionString: String, isPositionExplicit: Bool) {
        self.specifier = specifier
        self.isPositionExplicit = isPositionExplicit
        // ! is safe here because the regular expression only matches digits.
        position = Int(positionString)!
    }
}
