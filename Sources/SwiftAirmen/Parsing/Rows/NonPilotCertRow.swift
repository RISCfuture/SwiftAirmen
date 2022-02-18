import Foundation

struct NonPilotCertRow: Decodable {
    var uniqueID: String
    var firstName: String?
    var lastName: String?
    var type: CertificateType
    var level: Level?
    var expirationDate: DateComponents?
    var ratings = Set<Rating>()
    
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
            guard case .rigger = type else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            guard let level = Level.Rigger(rawValue: levelStr) else {
                throw Errors.unknownCertificateLevel(levelStr, uniqueID: uniqueID)
            }
            self.level = .rigger(level)
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
    }
    
    struct TypeDecodingConfig {
        let uniqueID: String
        let certType: CertificateType
    }
    
    enum CertificateType: String {
        case groundInstructor = "G"
        case mechanic = "M"
        case controlTowerOperator = "T"
        case repairman = "R"
        case repairmanExperimental = "I"
        case repairmanLightSport = "L"
        case rigger = "W"
        case dispatcher = "D"
        case navigator = "N"
        case navigatorLessee = "J"
    }
    
    enum Level {
        case rigger(_ level: Rigger)
        
        enum Rigger: String {
            case master = "U"
            case senior = "W"
        }
    }
    
    enum Rating: DecodableWithConfiguration, Hashable {
        typealias DecodingConfiguration = TypeDecodingConfig
        
        case mechanic(_ rating: Mechanic)
        case groundInstructor(_ rating: GroundInstructor)
        case repairmanLightSport(_ rating: RepairmanLightSport)
        case rigger(_ rating: Rigger, level: Level.Rigger)
        
        init(from decoder: Decoder, configuration: DecodingConfiguration) throws {
            let container = try decoder.singleValueContainer()
            let ratingStr = trim(try container.decode(String.self))!
            
            switch configuration.certType {
                case .mechanic:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = Mechanic(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .mechanic(rating)
                case .groundInstructor:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = GroundInstructor(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .groundInstructor(rating)
                case .repairmanLightSport:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    guard parts[0] == configuration.certType.rawValue else {
                        throw Errors.unknownRatingLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = RepairmanLightSport(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .repairmanLightSport(rating)
                case .rigger:
                    let parts = ratingStr.split(separator: "/")
                    guard parts.count == 2 else {
                        throw Errors.invalidRating(ratingStr, uniqueID: configuration.uniqueID)
                    }
                    
                    guard let level = Level.Rigger(rawValue: String(parts[0])) else {
                        throw Errors.unknownCertificateLevel(String(parts[0]), uniqueID: configuration.uniqueID)
                    }
                    guard let rating = Rigger(rawValue: String(parts[1])) else {
                        throw Errors.unknownRating(String(parts[1]), uniqueID: configuration.uniqueID)
                    }
                    self = .rigger(rating, level: level)
                default:
                    throw Errors.unknownRating(ratingStr, uniqueID: configuration.uniqueID)
            }
        }
        
        enum Mechanic: String {
            case airframe = "AIRFR"
            case powerplant = "POWER"
        }
        
        enum GroundInstructor: String {
            case basic = "BASIC"
            case advanced = "ADV"
            case instrument = "INST"
        }
        
        enum RepairmanLightSport: String {
            case maintenance = "MAINT"
            case inspection = "INSPT"
        }
        
        enum Rigger: String {
            case back = "BACK"
            case chest = "CHEST"
            case seat = "SEAT"
            case lap = "LAP"
        }
    }
    }
