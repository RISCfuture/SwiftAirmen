import Foundation
import SwiftAirmen

// Report keys for the values the parser returns. They are spelled out rather
// than derived from `String(describing:)`, so that renaming a case in the
// library cannot silently rewrite the keys a baseline is compared against.

extension Certificate {
  /// The kind of certificate this is, disregarding its ratings.
  var kind: String {
    switch self {
      case .pilot: "pilot"
      case .flightInstructor: "flightInstructor"
      case .authorizedAircraftInstructor: "authorizedAircraftInstructor"
      case .remotePilot: "remotePilot"
      case .groundInstructor: "groundInstructor"
      case .flightEngineer: "flightEngineer"
      case .flightEngineerLessee: "flightEngineerLessee"
      case .flightEngineerForeign: "flightEngineerForeign"
      case .mechanic: "mechanic"
      case .controlTowerOperator: "controlTowerOperator"
      case .repairman: "repairman"
      case .repairmanExperimental: "repairmanExperimental"
      case .repairmanLightSport: "repairmanLightSport"
      case .rigger: "rigger"
      case .dispatcher: "dispatcher"
      case .navigator: "navigator"
      case .navigatorLessee: "navigatorLessee"
    }
  }
}

extension Error {
  /// How this error is bucketed in a run report.
  ///
  /// The offending token is part of the name, so a distribution that introduces
  /// a rating code produces one bucket naming that code rather than scattering
  /// it across a bucket per airman. The airman ID is left out for the same
  /// reason.
  var reportKind: String {
    guard let error = self as? SwiftAirmen.Errors else {
      return "other[\(type(of: self))]"
    }
    switch error {
      case .invalidDate(let date): return "invalidDate[\(date)]"
      case .certificateTypeNotGiven: return "certificateTypeNotGiven"
      case .levelNotGiven: return "levelNotGiven"
      case .expirationDateNotGiven: return "expirationDateNotGiven"
      case .medicalWithoutDate: return "medicalWithoutDate"
      case .unknownMedicalClass(let medicalClass, _): return "unknownMedicalClass[\(medicalClass)]"
      case .unknownCertificateType(let type, _): return "unknownCertificateType[\(type)]"
      case .unknownRating(let rating, _): return "unknownRating[\(rating)]"
      case .unknownCertificateLevel(let level, _): return "unknownCertificateLevel[\(level)]"
      case .unknownRatingLevel(let level, _): return "unknownRatingLevel[\(level)]"
      case .invalidRating(let rating, _): return "invalidRating[\(rating)]"
      case .networkError: return "networkError"
      case .fileNotFound(let url): return "fileNotFound[\(url.lastPathComponent)]"
    }
  }
}
