import Foundation
import Testing

@testable import SwiftAirmen

@Suite("Basic Row Parser")
struct BasicRowParserTests {

  @Test("Parse medical class 8 as unknown")
  func medicalClass8() throws {
    let parser = BasicRowParser()
    let fields = [
      "A0000001", "JOHN", "DOE", "123 MAIN ST", "", "SEATTLE", "WA", "98101",
      "USA", "WN", "8", "010124", "013126", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))
    #expect(airman.medical == nil)  // Class 8 should result in nil medical
  }

  @Test("Parse BasicMed when no medical class but course date exists")
  func basicMedWithoutMedicalClass() throws {
    let parser = BasicRowParser()
    let fields = [
      "A0000002", "JANE", "SMITH", "", "", "", "", "",
      "", "", "", "", "", "110122", "110124"
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if case .basicMed(let courseDate, _, let cmecDate) = airman.medical {
      #expect(courseDate.year == 2022)
      #expect(courseDate.month == 11)
      #expect(courseDate.day == 1)
      #expect(cmecDate?.year == 2024)
      #expect(cmecDate?.month == 11)
      #expect(cmecDate?.day == 1)
    } else {
      Issue.record("Expected BasicMed")
    }
  }

  @Test("Throw error when medical class exists but date is missing", arguments: ["1", "2", "3"])
  func medicalWithoutDate(medClass: String) throws {
    let parser = BasicRowParser()
    let fields = [
      "A0000003", "BOB", "JONES", "", "", "", "", "",
      "", "", medClass, "", "", "", ""
    ]

    #expect {
      _ = try parser.parse(fields: fields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .medicalWithoutDate(uniqueID: "A0000003") = airmenError
      else {
        return false
      }
      return true
    }
  }

  @Test("Handle empty address fields")
  func emptyAddress() throws {
    let parser = BasicRowParser()
    let fields = [
      "A0000004", "ALICE", "WILSON", "", "", "", "", "",
      "", "", "", "", "", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))
    #expect(airman.address == nil)  // All empty address fields should result in nil
  }

  @Test("Parse complete address")
  func completeAddress() throws {
    let parser = BasicRowParser()
    let fields = [
      "A0000005", "CHARLIE", "BROWN", "789 PINE RD", "APT 5B", "CHICAGO", "IL", "60601",
      "USA", "GL", "", "", "", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))
    #expect(airman.address?.street1 == "789 PINE RD")
    #expect(airman.address?.street2 == "APT 5B")
    #expect(airman.address?.city == "CHICAGO")
    #expect(airman.address?.state == "IL")
    #expect(airman.address?.zipCode == "60601")
    #expect(airman.address?.country == "USA")
    #expect(airman.address?.region == "GL")
  }
}

@Suite("Pilot Cert Row Parser")
struct PilotCertRowParserTests {

  @Test("Parse centerline thrust rating")
  func centerlineThrustRating() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000001", "JOHN", "DOE", "P", "C", "",
      "C/AMELC", "C/ASEL", "", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .pilot(let level, let ratings, let centerline) = cert
    {
      #expect(level == .commercial)
      #expect(centerline == true)
      #expect(ratings.contains(.categoryClass(.airplaneMultiEngineLand, level: .commercial)))
      #expect(ratings.contains(.categoryClass(.airplaneSingleEngineLand, level: .commercial)))
    } else {
      Issue.record("Expected pilot certificate with centerline thrust")
    }
  }

  @Test("Parse combined instrument ratings")
  func combinedInstrumentRatings() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000002", "JANE", "SMITH", "P", "A", "",
      "A/INSTI", "", "", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .pilot(_, let ratings, _) = cert
    {
      #expect(ratings.contains(.instrument(.airplane)))
      #expect(ratings.contains(.instrument(.helicopter)))
    } else {
      Issue.record("Expected pilot certificate with instrument ratings")
    }
  }

  @Test("Parse type ratings with levels")
  func typeRatingsWithLevels() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000003", "BOB", "JONES", "P", "A", "",
      "A/ASEL", "", "", "", "", "", "", "", "", "", "",
      "A/B737", "C/CE500", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .pilot(let level, let ratings, _) = cert
    {
      #expect(level == .airlineTransport)
      #expect(ratings.contains(.type("B737", level: .airlineTransport)))
      #expect(ratings.contains(.type("CE500", level: .commercial)))
    }
  }

  @Test("Throw error for pilot cert without level")
  func pilotCertWithoutLevel() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000004", "ALICE", "WILSON", "P", "", "",
      "A-SEL", "", "", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    #expect {
      _ = try parser.parse(fields: fields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .levelNotGiven(uniqueID: "A0000004") = airmenError
      else {
        return false
      }
      return true
    }
  }

  @Test("Parse flight instructor with expiration")
  func flightInstructorWithExpiration() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000005", "CHARLIE", "BROWN", "F", "", "123125",
      "F/ASME", "F/INSTA", "F/SPORT", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .flightInstructor(let ratings, let expirationDate) = cert
    {
      #expect(ratings.contains(.category(.airplaneSingleEngine)))
      #expect(ratings.contains(.category(.airplaneMultiEngine)))
      #expect(ratings.contains(.instrument(.airplane)))
      #expect(ratings.contains(.sport))
      #expect(expirationDate.year == 2025)
      #expect(expirationDate.month == 12)
      #expect(expirationDate.day == 31)
    } else {
      Issue.record("Expected flight instructor certificate")
    }
  }

  @Test("Throw error for CFI without expiration date")
  func cfiWithoutExpiration() throws {
    let parser = PilotCertRowParser()
    let fields = [
      "A0000006", "DAVID", "TAYLOR", "F", "", "",
      "F/ASE", "", "", "", "", "", "", "", "", "", "",
      "", "", ""
    ]

    #expect {
      _ = try parser.parse(fields: fields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .expirationDateNotGiven(uniqueID: "A0000006") = airmenError
      else {
        return false
      }
      return true
    }
  }
}

@Suite("Non-Pilot Cert Row Parser")
struct NonPilotCertRowParserTests {

  @Test("Parse mechanic with A&P ratings")
  func mechanicWithAP() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000001", "FRANK", "HARRIS", "M", "", "",
      "M/A", "M/P", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .mechanic(let ratings) = cert
    {
      #expect(ratings.contains(.airframe))
      #expect(ratings.contains(.powerplant))
    } else {
      Issue.record("Expected mechanic certificate")
    }
  }

  @Test("Parse rigger with level requirements")
  func riggerWithLevel() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000002", "GRACE", "CLARK", "W", "M", "",
      "M/B", "S/S", "M/C", "S/L"
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .rigger(let level, let ratings) = cert
    {
      #expect(level == .master)
      #expect(ratings.contains(.back(level: .master)))
      #expect(ratings.contains(.seat(level: .senior)))
      #expect(ratings.contains(.chest(level: .master)))
      #expect(ratings.contains(.lap(level: .senior)))
    } else {
      Issue.record("Expected rigger certificate")
    }
  }

  @Test("Parse ground instructor ratings")
  func groundInstructorRatings() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000003", "HENRY", "LEWIS", "G", "", "",
      "G/BGI", "G/AGI", "G/IGI", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .groundInstructor(let ratings) = cert
    {
      #expect(ratings.contains(.basic))
      #expect(ratings.contains(.advanced))
      #expect(ratings.contains(.instrument))
    } else {
      Issue.record("Expected ground instructor certificate")
    }
  }

  @Test("Parse repairman light sport with ratings")
  func repairmanLightSport() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000004", "IDA", "ROBINSON", "L", "", "",
      "L/I", "L/M", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))

    if let cert = airman.certificates.first,
      case .repairmanLightSport(let ratings) = cert
    {
      #expect(ratings.contains(.inspection))
      #expect(ratings.contains(.maintenance))
    } else {
      Issue.record("Expected repairman light sport certificate")
    }
  }

  @Test("Throw error for rigger without level")
  func riggerWithoutLevel() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000005", "JACK", "THOMPSON", "W", "", "",
      "M/B", "", "", ""
    ]

    #expect {
      _ = try parser.parse(fields: fields)
    } throws: { error in
      guard let airmenError = error as? Errors,
        case .levelNotGiven(uniqueID: "A0000005") = airmenError
      else {
        return false
      }
      return true
    }
  }

  @Test("Parse dispatcher certificate")
  func dispatcherCertificate() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000006", "KAREN", "WHITE", "D", "", "",
      "", "", "", ""
    ]

    let airman = try #require(try parser.parse(fields: fields))
    #expect(airman.certificates.first == .dispatcher)
  }

  @Test("Parse control tower operator")
  func controlTowerOperator() throws {
    let parser = NonPilotCertRowParser()
    let fields = [
      "A0000007", "LEO", "GARCIA", "T", "", "",
      "", "", "", ""
    ]

    guard let airman = try parser.parse(fields: fields) else {
      Issue.record("Failed to parse airman")
      return
    }
    #expect(airman.certificates.first == .controlTowerOperator)
  }
}
