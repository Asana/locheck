//
//  Sequence.swift
//
//
//  Created by Steve Landey on 8/27/21.
//

import Foundation

extension Sequence {
    func lo_makeDictionary<Key>(makeKey: (Element) -> Key) -> [Key: Element] where Key: Hashable {
        var dict = [Key: Element]()
        for item in self {
            dict[makeKey(item)] = item
        }
        return dict
    }
}
