import Foundation

struct PilotCertRow: Decodable {
    var uniqueID: String
    var firstName: String?
    var lastName: String?
    var type: CertificateType
    var level: Level?
    var expirationDate: DateComponents?
    var ratings = Set<Rating>()
    var typeRatings = Set<TypeRating>()
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        uniqueID = try container.decode(String.self)
        firstName = trim(try container.decode(String.self))
        lastName = trim(try container.decode(String.self))
        
        guard let typeStr = trim(try container.decode(String.self)) else {
            throw Errors.certificateTypeNotGiven(uniqueID: uniqueID)
        }
        guard let type = CertificateType(rawValue: typeStr) else {
            throw Errors.unknownCertificateType(typeStr, uniqueID: uniqueID)
            
        }
        self.type = type
        
        if let levelStr = trim(try container.decode(String.self)) {
            guard case .pilot = type else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            guard let level = Level.Pilot(rawValue: levelStr) else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            self.level = .pilot(level)
        } else {
            self.level = nil
        }
        
        expirationDate = try parseDate(try container.decode(String.self))
        
        let config = TypeDecodingConfig(uniqueID: uniqueID, certType: type)
        for _ in 1...11 {
            guard let rating = try container.decode(Rating?.self, configuration: config) else {
                continue
            }
            self.ratings.insert(rating)
        }
        for _ in 1...99 {
            guard let rating = try container.decode(TypeRating?.self, configuration: config) else {
                continue
            }
            self.typeRatings.insert(rating)
        }
    }
    
    struct TypeDecodingConfig {
        let uniqueID: String
        let certType: CertificateType
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
    
    enum Rating: DecodableWithConfiguration, Hashable {
        typealias DecodingConfiguration = TypeDecodingConfig
        
        case pilot(_ rating: Pilot, level: Level.Pilot)
        case flightInstructor(_ rating: FlightInstructor)
        case flightEngineer(_ rating: FlightEngineer)
        case flightEngineerForeign(_ rating: FlightEngineer)
        case remotePilot
        
        init(from decoder: Decoder, configuration: DecodingConfiguration) throws {
            let container = try decoder.singleValueContainer()
            let ratingStr = trim(try container.decode(String.self))!
            
            switch configuration.certType {
                case .pilot:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    
                    guard let level = Level.Pilot(rawValue: String(parts[0])) else {
                        throw Errors.unknownCertificateLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = Pilot(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .pilot(rating, level: level)
                case .flightInstructor:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = FlightInstructor(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .flightInstructor(rating)
                case .flightEngineer:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = FlightEngineer(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .flightEngineer(rating)
                case .remotePilot:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard parts[1] == "SUAS" else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .remotePilot
                case .flightEngineerForeign:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = FlightEngineer(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .flightEngineerForeign(rating)
                default:
                    throw Errors.unknownRating(ratingStr, uniqueID: configuration.uniqueID)
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
    
    struct TypeRating: DecodableWithConfiguration, Hashable {
        typealias DecodingConfiguration = TypeDecodingConfig
        
        var level: Level.Pilot
        var type: String
        
        init(from decoder: Decoder, configuration: PilotCertRow.TypeDecodingConfig) throws {
            let container = try decoder.singleValueContainer()
            let ratingStr = trim(try container.decode(String.self))!
            
            let parts = ratingStr.split(separator: "/")
            guard parts.count == 2 else {
                throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
            }
            
            guard let level = Level.Pilot(rawValue: String(parts[0])) else {
                throw Errors.unknownCertificateLevel(String(parts[0]), uniqueID: configuration.uniqueID)
            }
            self.level = level
            
            type = String(parts[1])
        }
    }
    }
