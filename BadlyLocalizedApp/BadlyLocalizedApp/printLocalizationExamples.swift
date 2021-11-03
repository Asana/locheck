//
//  printLocalizationExamples.swift
//  BadlyLocalizedApp
//
//  Created by Steve Landey on 9/1/21.
//

import Foundation

func printLocalizationExamples() {
    print(NSLocalizedString("bad-specifier", comment: ""))
    // This would be a crash, uncomment to test
//    print(String.localizedStringWithFormat(NSLocalizedString("bad-specifier", comment: ""), 1))

    print(NSLocalizedString("bad-order", comment: ""))
    print(String.localizedStringWithFormat(NSLocalizedString("bad-order", comment: ""), 2, 3))

    // This would be a crash, uncomment to test
    print(NSLocalizedString("bad-order-causes-bad-type", comment: ""))
//    print(String.localizedStringWithFormat(NSLocalizedString("bad-order-causes-bad-type", comment: ""), 2, "Steve"))

    print(String.localizedStringWithFormat(NSLocalizedString("arg-order-test", comment: ""), "one", "two"))
    print("Done")
}
