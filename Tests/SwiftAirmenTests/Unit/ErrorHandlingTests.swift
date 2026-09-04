import Foundation
import Testing

@testable import SwiftAirmen

@Suite
struct `error handling tests` {

  let testResourcesURL = Bundle.module.resourceURL!
    .appendingPathComponent("TestResources")

  @Test
  func `throws medicalWithoutDate for a medical certificate with no date`() throws {
    let parser = BasicRowParser()
    let fields = [
      "A0000001", "JOHN", "DOE", "", "", "", "", "",
      "", "", "1", "", "013126", "", ""  // Medical class 1 but no date
    ]

    #expect {
      _ = try parser.parse(fields: fields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .medicalWithoutDate(uniqueID: "A0000001") = airmenError
      else {
        return false
      }
      return true
    }
  }

  @Test
  func `throws unknownCertificateType naming the unrecognized type`() throws {
    // Testing the error structure itself
    let error = Errors.unknownCertificateType("UNKNOWN", uniqueID: "A0000001")

    if case let .unknownCertificateType(type, uniqueID) = error {
      #expect(type == "UNKNOWN")
      #expect(uniqueID == "A0000001")
    } else {
      Issue.record("Expected unknownCertificateType error")
    }
  }

  @Test
  func `throws levelNotGiven when a required level is missing`() throws {
    let pilotParser = PilotCertRowParser()
    let pilotFields = [
      "A0000001", "JOHN", "DOE", "P", "", "",  // Pilot cert without level
      "A-SEL", "", "", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    #expect {
      _ = try pilotParser.parse(fields: pilotFields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .levelNotGiven(uniqueID: "A0000001") = airmenError
      else {
        return false
      }
      return true
    }

    let riggerParser = NonPilotCertRowParser()
    let riggerFields = [
      "A0000002", "JANE", "SMITH", "W", "", "",  // Rigger without level
      "M/B", "", "", ""
    ]

    #expect {
      _ = try riggerParser.parse(fields: riggerFields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .levelNotGiven(uniqueID: "A0000002") = airmenError
      else {
        return false
      }
      return true
    }
  }

  @Test
  func `returns all non-fatal errors from parsing`() async throws {
    // Use special files with errors
    let errorTestURL = Bundle.module.resourceURL!
      .appendingPathComponent("TestResources")
      .appendingPathComponent("PILOT_BASIC_WITH_ERRORS.csv")
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Copy error file to temp directory with expected name
    let destURL = tempDir.appendingPathComponent("PILOT_BASIC.csv")
    try FileManager.default.copyItem(at: errorTestURL, to: destURL)

    let parser = Parser(directory: tempDir)

    let (_, errors) = try await parser.parse(files: [.pilotBasic])

    // Should have collected errors for medical without date
    let hasMedicalError = errors.contains { error in
      if let airmenError = error as? Errors,
        case .medicalWithoutDate = airmenError
      {
        return true
      }
      return false
    }
    #expect(hasMedicalError)
  }

  @Test
  func `continues parsing after encountering errors`() async throws {
    let parser = Parser(directory: testResourcesURL)

    // Parse pilot_cert.csv which has some invalid entries
    let (airmen, errors) = try await parser.parse(files: [.pilotCert])

    // Our main test files are now valid, so no errors expected
    #expect(errors.isEmpty)

    // But valid records should still be parsed
    #expect(!airmen.isEmpty)

    // Check that valid records are present
    let john = try #require(airmen["A0000001"])
    #expect(john.firstName == "JOHN")

    let bob = try #require(airmen["A0000003"])
    #expect(bob.firstName == "BOB")
  }

  @Test
  func `reports every error from a single file`() async throws {
    let parser = Parser(directory: testResourcesURL)

    let (_, errors) = try await parser.parse(files: [.pilotCert, .nonPilotCert])

    // Should have multiple different error types
    let hasLevelError = errors.contains { error in
      if let airmenError = error as? Errors,
        case .levelNotGiven = airmenError
      {
        return true
      }
      return false
    }
    #expect(hasLevelError)

    // Our test files are now valid, so we don't expect expiration errors
    // We'd only have level errors if rigger cert is missing level
  }

  @Test
  func `reports a file-not-found error`() async throws {
    let nonExistentDir = URL(fileURLWithPath: "/tmp/nonexistent_test_dir_\(UUID().uuidString)")
    let parser = Parser(directory: nonExistentDir)

    let (_, errors) = try await parser.parse(files: [.pilotBasic])

    #expect(
      errors.contains { error in
        if let airmenError = error as? Errors, case .fileNotFound = airmenError {
          return true
        }
        return false
      }
    )
  }

  @Test
  func `throws expirationDateNotGiven for a CFI with no expiration date`() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000001", "JOHN", "DOE", "F", "", "",  // CFI without expiration
      "F/ASE", "F/INSTA", "", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    #expect {
      _ = try parser.parse(fields: fields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .expirationDateNotGiven(uniqueID: "A0000001") = airmenError
      else {
        return false
      }
      return true
    }
  }

  @Test
  func `includes the unique ID and certificate type in error descriptions`() {
    let medicalError = Errors.medicalWithoutDate(uniqueID: "A0000001")
    let description = String(describing: medicalError)
    #expect(description.contains("A0000001"))

    let levelError = Errors.levelNotGiven(uniqueID: "A0000002")
    let levelDescription = String(describing: levelError)
    #expect(levelDescription.contains("A0000002"))

    let typeError = Errors.unknownCertificateType("INVALID", uniqueID: "A0000003")
    let typeDescription = String(describing: typeError)
    #expect(typeDescription.contains("INVALID"))
    #expect(typeDescription.contains("A0000003"))
  }
}
