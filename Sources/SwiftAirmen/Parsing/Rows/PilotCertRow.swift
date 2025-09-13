import Foundation
import StreamingCSV

@CSVRowDecoderBuilder
struct PilotCertRow {
    @Field var uniqueID: String
    @Field var firstName: String?
    @Field var lastName: String?
    @Field var typeRaw: String
    @Field var levelRaw: String?
    @Field var expirationDateRaw: String?
    @Fields(11)
    var ratingStrings: [String]  // Up to 11 regular ratings
    @Fields var typeRatingStrings: [String]    // Remaining fields are type ratings

    // Parsed values
    var type: CertificateType {
        get throws {
            let trimmed = typeRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let type = CertificateType(rawValue: trimmed) else {
                throw Errors.unknownCertificateType(trimmed, uniqueID: uniqueID)
            }
            return type
        }
    }

    var level: Level? {
        get throws {
            guard let levelStr = levelRaw?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !levelStr.isEmpty else { return nil }

            let certType = try self.type
            guard case .pilot = certType else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            guard let level = Level.Pilot(rawValue: levelStr) else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            return .pilot(level)
        }
    }

    var expirationDate: DateComponents? {
        guard let raw = expirationDateRaw else { return nil }
        return DateComponents(csvString: raw)
    }

    var ratings: Set<Rating> {
        get throws {
            var result = Set<Rating>()
            let certType = try self.type

            for ratingStr in ratingStrings {
                let trimmed = ratingStr.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                let rating = try Rating.parse(from: trimmed, certType: certType, uniqueID: uniqueID)
                result.insert(rating)
            }
            return result
        }
    }

    var typeRatings: Set<TypeRating> {
        get throws {
            var result = Set<TypeRating>()

            for ratingStr in typeRatingStrings {
                let trimmed = ratingStr.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                let rating = try TypeRating.parse(from: trimmed, uniqueID: uniqueID)
                result.insert(rating)
            }
            return result
        }
    }

    enum CertificateType: String {
        case pilot = "P"
        case flightInstructor = "F"
        case authorizedAircraftInstructor = "A"
        case remotePilot = "U"
        case flightEngineer = "E"
        case flightEngineerLessee = "H"
        case flightEngineerForeign = "X"
    }

    enum Level {
        case pilot(_ level: Pilot)

        enum Pilot: String {
            case airlineTransport = "A"
            case commercial = "C"
            case `private` = "P"
            case recreational = "V"
            case sport = "T"
            case student = "S"
        }
    }

    enum Rating: Hashable {
        case pilot(_ rating: Pilot, level: Level.Pilot)
        case flightInstructor(_ rating: FlightInstructor)
        case flightEngineer(_ rating: FlightEngineer)
        case flightEngineerForeign(_ rating: FlightEngineer)
        case remotePilot

        static func parse(from ratingStr: String, certType: CertificateType, uniqueID: String) throws -> Self {
            switch certType {
            case .pilot:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }

                guard let level = Level.Pilot(rawValue: String(parts[0])) else {
                    throw Errors.unknownCertificateLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = Pilot(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .pilot(rating, level: level)

            case .flightInstructor:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = FlightInstructor(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .flightInstructor(rating)

            case .flightEngineer:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = FlightEngineer(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .flightEngineer(rating)

            case .remotePilot:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard parts[1] == "SUAS" else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .remotePilot

            case .flightEngineerForeign:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = FlightEngineer(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .flightEngineerForeign(rating)

            default:
                throw Errors.unknownRating(ratingStr, uniqueID: uniqueID)
            }
        }

        enum Pilot: String {
            case airplaneSingleEngineLand = "ASEL"
            case airplaneSingleEngineSea = "ASES"
            case airplaneMultiEngineLand = "AMEL"
            case airplaneMultiEngineSea = "AMES"
            case glider = "GL"
            case rotorcraftHelicopter = "HEL"
            case instrumentAirplane = "INSTA"
            case instrumentAirplaneHelicopter = "INSTI"
            case instrumentHelicopter = "INSTH"
            case rotorcraftGyroplane = "GYRO"
            case ltaBalloon = "BAL"
            case amelCenterlineThrust = "AMELC"
            case ltaAirship = "AIR"
            case rotorcraftHelicopterGyroplane = "HELGY"
            case poweredLift = "PLIFT"
            case instrumentPoweredLift = "INSTP"
            case sport = "SPORT"
        }

        enum FlightInstructor: String {
            case airplaneSingleEngine = "ASE"
            case instrumentAirplane = "INSTA"
            case airplaneSingleMultiEngine = "ASME"
            case rotorcraftHelicopter = "HEL"
            case glider = "GL"
            case sport = "SPORT"
            case rotorcraftGyroplane = "GYRO"
            case instrumentAirplaneHelicopter = "INSTI"
            case instrumentHelicopter = "INSTH"
            case airplaneMultiEngine = "AME"
            case rotorcraftHelicopterGyroplane = "HELGY"
            case poweredLift = "PLIFT"
            case instrumentPoweredLift = "INSTP"
        }

        enum FlightEngineer: String {
            case jet = "JET"
            case turboprop = "TPROP"
            case reciprocating = "RECIP"
        }
    }

    struct TypeRating: Hashable {
        var level: Level.Pilot
        var type: String

        static func parse(from ratingStr: String, uniqueID: String) throws -> Self {
            let parts = ratingStr.split(separator: "/")
            guard parts.count == 2 else {
                throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
            }

            guard let level = Level.Pilot(rawValue: String(parts[0])) else {
                throw Errors.unknownCertificateLevel(String(parts[0]), uniqueID: uniqueID)
            }

            return Self(level: level, type: String(parts[1]))
        }
    }
}
