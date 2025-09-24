import Foundation
import StreamingCSV

protocol RowParser: Sendable {
  associatedtype RowType: CSVDecodableRow

  init()
  func parseRow(_ row: RowType) throws -> Airman
}

extension RowParser {
  func parse(fields: [String]) throws -> Airman? {
    guard let row = RowType(from: fields) else { return nil }
    return try parseRow(row)
  }
}

// MARK: - BasicRowParser

final class BasicRowParser: RowParser, @unchecked Sendable {
  func parseRow(_ row: AirmanBasicRow) throws -> Airman {
    var airman = Airman(id: row.uniqueID)
    airman.firstName = row.firstName
    airman.lastName = row.lastName

    if airman.address == nil { airman.address = Address() }
    airman.address!.street1 = row.street1
    airman.address!.street2 = row.street2
    airman.address!.city = row.city
    airman.address!.state = row.state
    airman.address!.zipCode = row.zipCode
    airman.address!.country = row.country
    airman.address!.region = row.region
    if airman.address!.isEmpty { airman.address = nil }

    if let medClass = row.medicalClass {
      guard let medicalDate = row.medicalDate else {
        throw Errors.medicalWithoutDate(uniqueID: row.uniqueID)
      }

      switch medClass {
        case .first:
          airman.medical = .FAA(
            .first,
            date: medicalDate,
            expirationDate: row.medicalExpirationDate
          )
        case .second:
          airman.medical = .FAA(
            .second,
            date: medicalDate,
            expirationDate: row.medicalExpirationDate
          )
        case .third:
          airman.medical = .FAA(
            .third,
            date: medicalDate,
            expirationDate: row.medicalExpirationDate
          )
        case .unknown8:
          airman.medical = nil
      }
    } else {
      if let basicMedCourseDate = row.basicMedCourseDate {
        airman.medical = .basicMed(
          courseDate: basicMedCourseDate,
          expirationDate: row.medicalExpirationDate,
          CMECDate: row.basicMedCMECDate
        )
      } else {
        airman.medical = nil
      }
    }

    return airman
  }
}

// MARK: - PilotCertRowParser

final class PilotCertRowParser: RowParser, @unchecked Sendable {
  func parseRow(_ row: PilotCertRow) throws -> Airman {
    var airman = Airman(id: row.uniqueID)
    airman.firstName = row.firstName
    airman.lastName = row.lastName

    switch try row.type {
      case .pilot:
        guard let rowLevel = try row.level else {
          throw Errors.levelNotGiven(uniqueID: row.uniqueID)
        }
        guard case .pilot(let rowPilotLevel) = rowLevel else {
          fatalError("Certificate type and level mismatch")
        }
        let level = self.convertLevel(rowPilotLevel)

        var ratings = Set<PilotRating>()
        var centerlineThrust = false
        for rowRating in try row.ratings {
          guard case .pilot(let rowPilotRating, let ratingLevel) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }

          switch rowPilotRating {
            case .airplaneSingleEngineLand:
              ratings.insert(
                .categoryClass(.airplaneSingleEngineLand, level: self.convertLevel(ratingLevel))
              )
            case .airplaneSingleEngineSea:
              ratings.insert(
                .categoryClass(.airplaneSingleEngineSea, level: self.convertLevel(ratingLevel))
              )
            case .airplaneMultiEngineLand:
              ratings.insert(
                .categoryClass(.airplaneMultiEngineLand, level: self.convertLevel(ratingLevel))
              )
            case .airplaneMultiEngineSea:
              ratings.insert(
                .categoryClass(.airplaneMultiEngineSea, level: self.convertLevel(ratingLevel))
              )
            case .glider:
              ratings.insert(.categoryClass(.glider, level: self.convertLevel(ratingLevel)))
            case .rotorcraftHelicopter:
              ratings.insert(
                .categoryClass(.rotorcraftHelicopter, level: self.convertLevel(ratingLevel))
              )
            case .instrumentAirplane:
              ratings.insert(.instrument(.airplane))
            case .instrumentAirplaneHelicopter:
              ratings.insert(.instrument(.airplane))
              ratings.insert(.instrument(.helicopter))
            case .instrumentHelicopter:
              ratings.insert(.instrument(.helicopter))
            case .rotorcraftGyroplane:
              ratings.insert(
                .categoryClass(.rotorcraftGyroplane, level: self.convertLevel(ratingLevel))
              )
            case .ltaBalloon:
              ratings.insert(
                .categoryClass(.lighterThanAirBalloon, level: self.convertLevel(ratingLevel))
              )
            case .amelCenterlineThrust:
              ratings.insert(
                .categoryClass(.airplaneMultiEngineLand, level: self.convertLevel(ratingLevel))
              )
              centerlineThrust = true
            case .ltaAirship:
              ratings.insert(
                .categoryClass(.lighterThanAirAirship, level: self.convertLevel(ratingLevel))
              )
            case .rotorcraftHelicopterGyroplane:
              ratings.insert(
                .categoryClass(.rotorcraftHelicopter, level: self.convertLevel(ratingLevel))
              )
              ratings.insert(
                .categoryClass(.rotorcraftGyroplane, level: self.convertLevel(ratingLevel))
              )
            case .poweredLift:
              ratings.insert(.categoryClass(.poweredLift, level: self.convertLevel(ratingLevel)))
            case .instrumentPoweredLift:
              ratings.insert(.instrument(.poweredLift))
            case .sport: break
          }
        }

        for rowRating in try row.typeRatings {
          ratings.insert(.type(rowRating.type, level: self.convertLevel(rowRating.level)))
        }

        airman.certificates.append(
          .pilot(level: level, ratings: ratings, centerlineThrustOnly: centerlineThrust)
        )
      case .authorizedAircraftInstructor:
        airman.certificates.append(.authorizedAircraftInstructor)
      case .flightInstructor:
        var ratings = Set<FlightInstructorRating>()
        for rowRating in try row.ratings {
          guard case .flightInstructor(let rowCFIRating) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }
          switch rowCFIRating {
            case .airplaneSingleEngine:
              ratings.insert(.category(.airplaneSingleEngine))
            case .instrumentAirplane:
              ratings.insert(.instrument(.airplane))
            case .airplaneSingleMultiEngine:
              ratings.insert(.category(.airplaneSingleEngine))
              ratings.insert(.category(.airplaneMultiEngine))
            case .rotorcraftHelicopter:
              ratings.insert(.category(.rotorcraftHelicopter))
            case .glider:
              ratings.insert(.category(.glider))
            case .sport:
              ratings.insert(.sport)
            case .rotorcraftGyroplane:
              ratings.insert(.category(.rotorcraftGyroplane))
            case .instrumentAirplaneHelicopter:
              ratings.insert(.instrument(.airplane))
              ratings.insert(.instrument(.helicopter))
            case .instrumentHelicopter:
              ratings.insert(.instrument(.helicopter))
            case .airplaneMultiEngine:
              ratings.insert(.category(.airplaneMultiEngine))
            case .rotorcraftHelicopterGyroplane:
              ratings.insert(.category(.rotorcraftHelicopter))
              ratings.insert(.category(.rotorcraftGyroplane))
            case .poweredLift:
              ratings.insert(.category(.poweredLift))
            case .instrumentPoweredLift:
              ratings.insert(.instrument(.poweredLift))
          }
        }
        guard let expDate = row.expirationDate else {
          throw Errors.expirationDateNotGiven(uniqueID: row.uniqueID)
        }
        airman.certificates.append(.flightInstructor(ratings: ratings, expirationDate: expDate))
      case .remotePilot:
        airman.certificates.append(.remotePilot)
      case .flightEngineer:
        var ratings = Set<FlightEngineerRating>()
        for rowRating in try row.ratings {
          guard case .flightEngineer(let engRating) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }
          switch engRating {
            case .jet: ratings.insert(.jet)
            case .turboprop: ratings.insert(.turboprop)
            case .reciprocating: ratings.insert(.reciprocating)
          }
        }
        airman.certificates.append(.flightEngineer(ratings: ratings))
      case .flightEngineerLessee:
        airman.certificates.append(.flightEngineerLessee)
      case .flightEngineerForeign:
        var ratings = Set<FlightEngineerRating>()
        for rowRating in try row.ratings {
          guard case .flightEngineerForeign(let engRating) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }
          switch engRating {
            case .jet: ratings.insert(.jet)
            case .turboprop: ratings.insert(.turboprop)
            case .reciprocating: ratings.insert(.reciprocating)
          }
        }
        airman.certificates.append(.flightEngineerForeign(ratings: ratings))
    }

    return airman
  }

  private func convertLevel(_ level: PilotCertRow.Level.Pilot) -> PilotLevel {
    switch level {
      case .airlineTransport: return .airlineTransport
      case .commercial: return .commercial
      case .private: return .private
      case .recreational: return .recreational
      case .sport: return .sport
      case .student: return .student
    }
  }
}

// MARK: - NonPilotCertRowParser

final class NonPilotCertRowParser: RowParser, @unchecked Sendable {
  func parseRow(_ row: NonPilotCertRow) throws -> Airman {
    var airman = Airman(id: row.uniqueID)
    airman.firstName = row.firstName
    airman.lastName = row.lastName

    switch try row.type {
      case .groundInstructor:
        var ratings = Set<GroundInstructorRating>()
        for rowRating in try row.ratings {
          guard case .groundInstructor(let instructorRating) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }
          switch instructorRating {
            case .basic: ratings.insert(.basic)
            case .advanced: ratings.insert(.advanced)
            case .instrument: ratings.insert(.instrument)
          }
        }
        airman.certificates.append(.groundInstructor(ratings: ratings))
      case .mechanic:
        var ratings = Set<MechanicRating>()
        for rowRating in try row.ratings {
          guard case .mechanic(let mechRating) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }
          switch mechRating {
            case .airframe: ratings.insert(.airframe)
            case .powerplant: ratings.insert(.powerplant)
          }
        }
        airman.certificates.append(.mechanic(ratings: ratings))
      case .controlTowerOperator:
        airman.certificates.append(.controlTowerOperator)
      case .repairman:
        airman.certificates.append(.repairman)
      case .repairmanExperimental:
        airman.certificates.append(.repairmanExperimental)
      case .repairmanLightSport:
        var ratings = Set<RepairmanLightSportRating>()
        for rowRating in try row.ratings {
          guard case .repairmanLightSport(let repairmanRating) = rowRating else {
            fatalError("Certificate and rating type mismatch")
          }
          switch repairmanRating {
            case .inspection: ratings.insert(.inspection)
            case .maintenance: ratings.insert(.maintenance)
          }
        }
        airman.certificates.append(.repairmanLightSport(ratings: ratings))
      case .rigger:
        let level: RiggerLevel
        guard let rowLevel = try row.level else {
          throw Errors.levelNotGiven(uniqueID: row.uniqueID)
        }
        guard case .rigger(let riggerLevel) = rowLevel else {
          fatalError("Certificate type and level mismatch")
        }
        switch riggerLevel {
          case .master: level = .master
          case .senior: level = .senior
        }

        var ratings = Set<RiggerRating>()
        for rowRating in try row.ratings {
          guard case .rigger(let riggerRating, let riggerLevel) = rowRating else {
            fatalError("Certificate and rating mismatch")
          }
          let ratingLevel: RiggerLevel
          switch riggerLevel {
            case .master: ratingLevel = .master
            case .senior: ratingLevel = .senior
          }

          switch riggerRating {
            case .back: ratings.insert(.back(level: ratingLevel))
            case .chest: ratings.insert(.chest(level: ratingLevel))
            case .lap: ratings.insert(.lap(level: ratingLevel))
            case .seat: ratings.insert(.seat(level: ratingLevel))
          }
        }
        airman.certificates.append(.rigger(level: level, ratings: ratings))
      case .dispatcher:
        airman.certificates.append(.dispatcher)
      case .navigator:
        airman.certificates.append(.navigator)
      case .navigatorLessee:
        airman.certificates.append(.navigatorLessee)
    }

    return airman
  }
}
