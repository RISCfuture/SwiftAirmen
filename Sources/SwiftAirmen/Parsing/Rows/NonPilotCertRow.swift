import Foundation
import StreamingCSV

@CSVRowDecoderBuilder
struct NonPilotCertRow {
    @Field var uniqueID: String
    @Field var firstName: String?
    @Field var lastName: String?
    @Field var typeRaw: String
    @Field var levelRaw: String?
    @Field var expirationDateRaw: String?
    @Fields var ratingStrings: [String]  // All remaining fields are ratings

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
            guard case .rigger = certType else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            guard let level = Level.Rigger(rawValue: levelStr) else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            return .rigger(level)
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

    enum CertificateType: String {
        case groundInstructor = "G"
        case mechanic = "M"
        case controlTowerOperator = "T"
        case repairman = "R"
        case repairmanExperimental = "Q"
        case repairmanLightSport = "L"
        case rigger = "W"
        case dispatcher = "D"
        case navigator = "N"
        case navigatorLessee = "K"
    }

    enum Level {
        case rigger(_ level: Rigger)

        enum Rigger: String {
            case master = "M"
            case senior = "S"
        }
    }

    enum Rating: Hashable {
        case groundInstructor(_ rating: GroundInstructor)
        case mechanic(_ rating: Mechanic)
        case repairmanLightSport(_ rating: RepairmanLightSport)
        case rigger(_ rating: Rigger, level: Level.Rigger)

        static func parse(from ratingStr: String, certType: CertificateType, uniqueID: String) throws -> Self {
            switch certType {
            case .groundInstructor:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = GroundInstructor(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .groundInstructor(rating)

            case .mechanic:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = Mechanic(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .mechanic(rating)

            case .repairmanLightSport:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard parts[0] == certType.rawValue else {
                    throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = RepairmanLightSport(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .repairmanLightSport(rating)

            case .rigger:
                let parts = ratingStr.split(separator: "/")
                guard parts.count == 2 else {
                    throw Errors.invalidRating(ratingStr, uniqueID: uniqueID)
                }
                guard let level = Level.Rigger(rawValue: String(parts[0])) else {
                    throw Errors.unknownCertificateLevel(String(parts[0]), uniqueID: uniqueID)
                }
                guard let rating = Rigger(rawValue: String(parts[1])) else {
                    throw Errors.unknownRating(String(parts[1]), uniqueID: uniqueID)
                }
                return .rigger(rating, level: level)

            default:
                // Other certificate types don't have ratings in this format
                throw Errors.unknownRating(ratingStr, uniqueID: uniqueID)
            }
        }

        enum GroundInstructor: String {
            case basic = "BGI"
            case advanced = "AGI"
            case instrument = "IGI"
        }

        enum Mechanic: String {
            case airframe = "A"
            case powerplant = "P"
        }

        enum RepairmanLightSport: String {
            case inspection = "I"
            case maintenance = "M"
        }

        enum Rigger: String {
            case back = "B"
            case chest = "C"
            case lap = "L"
            case seat = "S"
        }
    }
}
