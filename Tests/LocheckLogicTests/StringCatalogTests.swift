//
//  StringCatalogTests.swift
//
//
//  Created by Uladzislau Birukou on 9/22/25.
//

@testable import LocheckLogic
import XCTest

final class StringCatalogTests: XCTestCase {
    func testValidStringCatalog() {
        let json = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "hello_world" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Hello, World!"
                  }
                },
                "de" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Hallo, Welt!"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """

        let data = json.data(using: .utf8)!
        let catalog = try! JSONDecoder().decode(StringCatalog.self, from: data)

        XCTAssertEqual(catalog.sourceLanguage, "en")
        XCTAssertEqual(catalog.version, "1.0")
        XCTAssertEqual(catalog.strings.count, 1)

        let helloWorldEntry = catalog.strings["hello_world"]!
        XCTAssertEqual(helloWorldEntry.localizations.count, 2)
        XCTAssertEqual(helloWorldEntry.localizations["en"]?.stringUnit?.value, "Hello, World!")
        XCTAssertEqual(helloWorldEntry.localizations["de"]?.stringUnit?.value, "Hallo, Welt!")
    }

    func testStringCatalogWithPluralForms() {
        let json = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "item_count" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "variations" : {
                    "plural" : {
                      "one" : {
                        "stringUnit" : {
                          "state" : "translated",
                          "value" : "%d item"
                        }
                      },
                      "other" : {
                        "stringUnit" : {
                          "state" : "translated",
                          "value" : "%d items"
                        }
                      }
                    }
                  }
                },
                "de" : {
                  "variations" : {
                    "plural" : {
                      "one" : {
                        "stringUnit" : {
                          "state" : "translated",
                          "value" : "%d Element"
                        }
                      },
                      "other" : {
                        "stringUnit" : {
                          "state" : "translated",
                          "value" : "%d Elemente"
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """

        let data = json.data(using: .utf8)!
        let catalog = try! JSONDecoder().decode(StringCatalog.self, from: data)

        let itemCountEntry = catalog.strings["item_count"]!
        let enPlurals = itemCountEntry.localizations["en"]?.variations?.plural
        let dePlurals = itemCountEntry.localizations["de"]?.variations?.plural

        XCTAssertNotNil(enPlurals)
        XCTAssertNotNil(dePlurals)
        XCTAssertEqual(enPlurals?["one"]?.stringUnit.value, "%d item")
        XCTAssertEqual(enPlurals?["other"]?.stringUnit.value, "%d items")
        XCTAssertEqual(dePlurals?["one"]?.stringUnit.value, "%d Element")
        XCTAssertEqual(dePlurals?["other"]?.stringUnit.value, "%d Elemente")
    }

    func testStringCatalogGenerateLocalizedPairs() {
        let json = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "greeting" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Hello, %@!"
                  }
                },
                "de" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Hallo, %@!"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """

        let data = json.data(using: .utf8)!
        let catalog = try! JSONDecoder().decode(StringCatalog.self, from: data)

        let greetingEntry = catalog.strings["greeting"]!
        let pairs = greetingEntry.getLocalizedStringPairs(
            key: "greeting",
            basePath: "/test/path",
            sourceLanguage: "en")

        XCTAssertEqual(pairs.count, 1) // Only one non-source language (ru)

        let pair = pairs[0]
        XCTAssertEqual(pair.key, "greeting")
        XCTAssertEqual(pair.base.string, "Hello, %@!")
        XCTAssertEqual(pair.translation.string, "Hallo, %@!")
        XCTAssertEqual(pair.path, "/test/path")

        // Check format arguments are parsed correctly
        XCTAssertEqual(pair.base.arguments.count, 1)
        XCTAssertEqual(pair.translation.arguments.count, 1)
        XCTAssertEqual(pair.base.arguments[0].specifier, "@")
        XCTAssertEqual(pair.translation.arguments[0].specifier, "@")
    }

    func testStringCatalogWithFormatArgumentMismatch() {
        let json = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "numbers" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Number: %d, String: %@"
                  }
                },
                "de" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "String: %@, Zahl: %s"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """

        let data = json.data(using: .utf8)!
        let catalog = try! JSONDecoder().decode(StringCatalog.self, from: data)

        let numbersEntry = catalog.strings["numbers"]!
        let pairs = numbersEntry.getLocalizedStringPairs(
            key: "numbers",
            basePath: "/test/path",
            sourceLanguage: "en")

        XCTAssertEqual(pairs.count, 1)

        let pair = pairs[0]

        // Base: %d (position 1), %@ (position 2)
        XCTAssertEqual(pair.base.arguments.count, 2)
        XCTAssertEqual(pair.base.arguments[0].position, 1)
        XCTAssertEqual(pair.base.arguments[0].specifier, "d")
        XCTAssertEqual(pair.base.arguments[1].position, 2)
        XCTAssertEqual(pair.base.arguments[1].specifier, "@")

        // Translation: %@ (position 1), %s (position 2)
        XCTAssertEqual(pair.translation.arguments.count, 2)
        XCTAssertEqual(pair.translation.arguments[0].position, 1)
        XCTAssertEqual(pair.translation.arguments[0].specifier, "@")
        XCTAssertEqual(pair.translation.arguments[1].position, 2)
        XCTAssertEqual(pair.translation.arguments[1].specifier, "s")
    }

    func testInvalidStringCatalogHandling() {
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)

        // Test with non-existent file
        let catalog = StringCatalog(path: "/non/existent/path.xcstrings", problemReporter: problemReporter)

        XCTAssertNil(catalog)
        XCTAssertTrue(problemReporter.hasError)
    }
}
