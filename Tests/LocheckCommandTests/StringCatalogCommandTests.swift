//
//  StringCatalogCommandTests.swift
//
//
//  Created by Uladzislau Birukou on 9/22/25.
//

import XCTest
import Files
import Foundation

final class StringCatalogCommandTests: XCTestCase {
    private var tempFolder: Folder!
    
    override func setUp() {
        super.setUp()
        let uuid = UUID().uuidString
        tempFolder = try! Folder.home.createSubfolderIfNeeded(withName: "StringCatalogCommandTests_\(uuid)")
    }
    
    override func tearDown() {
        try? tempFolder.delete()
        super.tearDown()
    }
    
    func testStringCatalogCommandWithValidFile() throws {
        let validCatalog = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "test_key" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Test Value"
                  }
                },
                "es" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Valor de Prueba"
                  }
                }
              }
            },
            "empty_key" : {
            }
          },
          "version" : "1.0"
        }
        """
        
        let catalogFile = try tempFolder.createFile(named: "test.xcstrings", contents: Data(validCatalog.utf8))
        
        // Test the command via executable
        let binary = productsDirectory.appendingPathComponent("locheck")
        let process = Process()
        process.executableURL = binary
        process.arguments = ["stringcatalog", catalogFile.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        // Valid file should exit with status 0
        XCTAssertEqual(process.terminationStatus, 0)
    }
    
    func testStringCatalogCommandWithProblematicFile() throws {
        let problematicCatalog = """
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
                "es" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "¡Hola!"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """
        
        let catalogFile = try tempFolder.createFile(named: "problematic.xcstrings", contents: Data(problematicCatalog.utf8))
        
        // Test the command via executable
        let binary = productsDirectory.appendingPathComponent("locheck")
        let process = Process()
        process.executableURL = binary
        process.arguments = ["stringcatalog", catalogFile.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        // This file only has warnings, which don't cause non-zero exit by default
        // So we just check that the process completes successfully
        // In real usage, you would use --treat-warnings-as-errors to get non-zero exit
        XCTAssertEqual(process.terminationStatus, 0)
    }
    
    func testStringCatalogCommandWithErrorsFile() throws {
        let catalogWithErrors = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "wrong_specifier" : {
              "extractionState" : "manual",
              "localizations" : {
                "en" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Count: %d"
                  }
                },
                "es" : {
                  "stringUnit" : {
                    "state" : "translated",
                    "value" : "Cuenta: %@"
                  }
                }
              }
            }
          },
          "version" : "1.0"
        }
        """
        
        let catalogFile = try tempFolder.createFile(named: "errors.xcstrings", contents: Data(catalogWithErrors.utf8))
        
        // Test the command via executable
        let binary = productsDirectory.appendingPathComponent("locheck")
        let process = Process()
        process.executableURL = binary
        process.arguments = ["stringcatalog", catalogFile.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        // File with errors should exit with non-zero status
        XCTAssertNotEqual(process.terminationStatus, 0)
    }
    
    func testStringCatalogCommandHelp() throws {
        let binary = productsDirectory.appendingPathComponent("locheck")
        let process = Process()
        process.executableURL = binary
        process.arguments = ["stringcatalog", "--help"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        XCTAssertTrue(output.contains("Validate String Catalog (.xcstrings) files"))
        XCTAssertEqual(process.terminationStatus, 0)
    }
    
    /// Returns path to the built products directory.
    private var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
}
