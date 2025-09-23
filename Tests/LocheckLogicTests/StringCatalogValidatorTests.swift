//
//  StringCatalogValidatorTests.swift
//
//
//  Created by Uladzislau Birukou on 9/22/25.
//

import XCTest
import Files
@testable import LocheckLogic

final class StringCatalogValidatorTests: XCTestCase {
    private var tempFolder: Folder!
    
    override func setUp() {
        super.setUp()
        let uuid = UUID().uuidString
        tempFolder = try! Folder.home.createSubfolderIfNeeded(withName: "StringCatalogTests_\(uuid)")
    }
    
    override func tearDown() {
        try? tempFolder.delete()
        super.tearDown()
    }
    
    func testValidStringCatalogValidation() throws {
        let validCatalog = """
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
        
        let catalogFile = try tempFolder.createFile(named: "test.xcstrings", contents: Data(validCatalog.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertFalse(problemReporter.hasError)
        XCTAssertFalse(problemReporter.hasWarning)
    }
    
    func testStringCatalogWithMissingArguments() throws {
        let catalogWithMissingArgs = """
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
                    "value" : "Hallo!"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """
        
        let catalogFile = try tempFolder.createFile(named: "test_missing_args.xcstrings", contents: Data(catalogWithMissingArgs.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertTrue(problemReporter.hasWarning) // Missing argument should generate warning
        
        let problems = problemReporter.problems
        XCTAssertTrue(problems.contains { localProblem in
            localProblem.problem.kindIdentifier == "string_has_missing_arguments"
        })
    }
    
    func testStringCatalogWithExtraArguments() throws {
        let catalogWithExtraArgs = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "greeting" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Hello!"
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
        
        let catalogFile = try tempFolder.createFile(named: "test_extra_args.xcstrings", contents: Data(catalogWithExtraArgs.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertTrue(problemReporter.hasWarning) // Extra argument should generate warning
        
        let problems = problemReporter.problems
        XCTAssertTrue(problems.contains { localProblem in
            localProblem.problem.kindIdentifier == "string_has_extra_arguments"
        })
    }
    
    func testStringCatalogWithInvalidArgumentSpecifier() throws {
        let catalogWithInvalidSpecifier = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "numbers" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Number: %d"
                  }
                },
                "de" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Zahl: %@"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """
        
        let catalogFile = try tempFolder.createFile(named: "test_invalid_specifier.xcstrings", contents: Data(catalogWithInvalidSpecifier.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertTrue(problemReporter.hasError) // Invalid specifier should generate error
        
        let problems = problemReporter.problems
        XCTAssertTrue(problems.contains { localProblem in
            localProblem.problem.kindIdentifier == "string_has_invalid_argument"
        })
    }
    
    func testStringCatalogWithNeedsWorkTranslation() throws {
        let catalogWithNeedsWork = """
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
                    "state" : "needs_work",
                    "value" : "Hallo, Welt!"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """
        
        let catalogFile = try tempFolder.createFile(named: "test_needs_work.xcstrings", contents: Data(catalogWithNeedsWork.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertTrue(problemReporter.hasWarning) // "needs work" should generate warning
        
        let problems = problemReporter.problems
        XCTAssertTrue(problems.contains { localProblem in
            localProblem.problem.kindIdentifier == "translation_needs_work"
        })
    }
    
    func testStringCatalogWithMissingPluralForm() throws {
        let catalogWithMissingPlural = """
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
        
        let catalogFile = try tempFolder.createFile(named: "test_missing_plural.xcstrings", contents: Data(catalogWithMissingPlural.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertTrue(problemReporter.hasWarning) // Missing "other" form should generate warning
        
        let problems = problemReporter.problems
        let missingPluralProblems = problems.filter { $0.problem.kindIdentifier == "missing_plural_form" }
        XCTAssertTrue(missingPluralProblems.count >= 1) // At least one missing plural form
    }
    
    func testStringCatalogWithPluralArgumentConsistency() throws {
        let catalogWithPlurals = """
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
        
        let catalogFile = try tempFolder.createFile(named: "test_valid_plurals.xcstrings", contents: Data(catalogWithPlurals.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        // Should not have format specifier errors since all plural forms use %d correctly
        let invalidArgumentProblems = problemReporter.problems.filter { $0.problem.kindIdentifier == "string_has_invalid_argument" }
        XCTAssertEqual(invalidArgumentProblems.count, 0)
    }
    
    func testInvalidJSONStringCatalog() throws {
        let invalidJSON = "{ invalid json }"
        
        let catalogFile = try tempFolder.createFile(named: "invalid.xcstrings", contents: Data(invalidJSON.utf8))
        let problemReporter = ProblemReporter(root: "", ignoredProblemIdentifiers: [], ignoreWarnings: false)
        
        parseAndValidateStringCatalog(stringCatalogFile: catalogFile, problemReporter: problemReporter)
        
        XCTAssertTrue(problemReporter.hasError)
        
        let problems = problemReporter.problems
        XCTAssertTrue(problems.contains { localProblem in
            localProblem.problem.kindIdentifier == "invalid_file"
        })
    }
}
