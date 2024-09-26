import Foundation

/// A certificate level for a pilot certificate.
public enum PilotLevel: Comparable, CustomStringConvertible, Sendable {

    /// A student pilot certificate.
    case student
    
    /// A sport pilot certificate.
    case sport
    
    /// A recreational pilot certificate.
    case recreational
    
    /// A private pilot certificate.
    case `private`
    
    /// A commercial pilot certificate.
    case commercial
    
    /// An airline transport pilot certificate.
    case airlineTransport
    
    /// An abbreviated description of the certificate level.
    public var description: String {
        switch self {
            case .student: return "ST"
            case .sport: return "SPL"
            case .recreational: return "RPL"
            case .private: return "PPL"
            case .commercial: return "CPL"
            case .airlineTransport: return "ATP"
        }
    }
}

/// Aircraft category/class combinations for a pilot certificate.
public enum PilotCategoryClass: Comparable, CustomStringConvertible, Sendable {
    /// The airplane category, single-engine land class.
    case airplaneSingleEngineLand
    
    /// The airplane category, single-engine sea class.
    case airplaneSingleEngineSea
    
    /// The airplane category, multi-engine land class.
    case airplaneMultiEngineLand
    
    /// The airplane category, multi-engine sea class.
    case airplaneMultiEngineSea
    
    /// The glider category and class.
    case glider
    
    /// The rotorcraft category, helicopter class.
    case rotorcraftHelicopter
    
    /// The rotorcraft category, gyroplane class.
    case rotorcraftGyroplane
    
    /// The lighter-than-air category, free balloon (hot air balloon) class.
    case lighterThanAirBalloon
    
    /// The lighter-than-air category, airship class.
    case lighterThanAirAirship
    
    /// The powered-lift category and class.
    case poweredLift
    
    /// An abbreviated description of the category and class.
    public var description: String {
        switch self {
            case .airplaneSingleEngineLand: return "ASEL"
            case .airplaneMultiEngineLand: return "AMEL"
            case .airplaneSingleEngineSea: return "ASES"
            case .airplaneMultiEngineSea: return "AMES"
            case .glider: return "GL"
            case .rotorcraftHelicopter: return "R-HEL"
            case .rotorcraftGyroplane: return "R-GYRO"
            case .lighterThanAirBalloon: return "LTA-BAL"
            case .lighterThanAirAirship: return "LTA-A/S"
            case .poweredLift: return "PL"
        }
    }
}


/// Aircraft categories for a pilot instrument rating.
public enum InstrumentCategory: Comparable, CustomStringConvertible, Sendable {

    /// The airplane category.
    case airplane
    
    /// The helicopter category.
    case helicopter
    
    /// The powered-lift category.
    case poweredLift
    
    public var description: String {
        switch self {
            case .airplane: return "A"
            case .helicopter: return "H"
            case .poweredLift: return "PL"
        }
    }
}


/// Ratings for a flight engineer certificate.
public enum FlightEngineerRating: Comparable, CustomStringConvertible, Sendable {

    /// Reciprocating engine rating.
    case reciprocating
    
    /// Turboprop engine rating.
    case turboprop
    
    /// Turbojet engine rating.
    case jet
    
    public var description: String {
        switch self {
            case .jet: return "jet"
            case .turboprop: return "t/p"
            case .reciprocating: return "recip."
        }
    }
}

/// Certificate levels for a parachute rigger certificate.
public enum RiggerLevel: Comparable, CustomStringConvertible, Sendable {

    /// Senior-level parachute rigger.
    case senior
    
    /// Master-level parachute rigger.
    case master
    
    public var description: String {
        switch self {
            case .senior: return "S"
            case .master: return "M"
        }
    }
}

/// Ratings for a parachute rigger certificate.
public enum RiggerRating: Comparable, Hashable, CustomStringConvertible, Sendable {

    /**
     A back type rating.
     
     - Parameter level: The rating level.
     */
    case back(level: RiggerLevel)
    
    /**
     A back type rating.
     
     - Parameter level: The rating level.
     */
    case chest(level: RiggerLevel)
    
    /**
     A back type rating.
     
     - Parameter level: The rating level.
     */
    case seat(level: RiggerLevel)
    
    /**
     A back type rating.
     
     - Parameter level: The rating level.
     */
    case lap(level: RiggerLevel)
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
            case let .back(lhsLevel):
                guard case let .back(rhsLevel) = rhs else { return false }
                return lhsLevel < rhsLevel
            case let .chest(lhsLevel):
                switch rhs {
                    case .back(_): return false
                    case let .chest(rhsLevel): return lhsLevel < rhsLevel
                    default: return true
                }
            case let .seat(lhsLevel):
                switch rhs {
                    case .back(_), .chest(_): return false
                    case let .seat(rhsLevel): return lhsLevel < rhsLevel
                    default: return true
                }
            case let .lap(lhsLevel):
                guard case let .lap(rhsLevel) = rhs else { return false }
                return lhsLevel < rhsLevel
        }
    }
    
    /// A human-readable description of the rating.
    public var description: String {
        switch self {
            case let .back(level): return "back (\(level))"
            case let .chest(level): return "chest (\(level))"
            case let .seat(level): return "seat (\(level))"
            case let .lap(level): return "lap (\(level))"
        }
    }
    
    func descriptionForLevel(_ level: RiggerLevel) -> String {
        switch self {
            case let .back(ratingLevel):
                if level == ratingLevel { return "back" }
                else { return description }
            case let .chest(ratingLevel):
                if level == ratingLevel { return "chest" }
                else { return description }
            case let .seat(ratingLevel):
                if level == ratingLevel { return "seat" }
                else { return description }
            case let .lap(ratingLevel):
                if level == ratingLevel { return "lap" }
                else { return description }
        }
    }
}

/// A rating applied to a pilot certificate.
public enum PilotRating: Comparable, Hashable, CustomStringConvertible, Sendable {

    /**
     A rating for a category and class of aircraft.
     
     - Parameter categoryClass: The aircraft category and class.
     - Parameter level: The certificate level for the rating.
     */
    case categoryClass(_ categoryClass: PilotCategoryClass, level: PilotLevel)
    
    /**
     An instrument rating for an aircraft category.
     
     - Parameter category: The aircraft category.
     */
    case instrument(_ category: InstrumentCategory)
    
    /**
     A type rating for a turbine or heavy aircraft.
     
     - Parameter type: The ICAO type code for the aircraft.
     - Parameter level: The certificate level for the rating.
     */
    case type(_ type: String, level: PilotLevel)
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
            case let .categoryClass(lhsCat, lhsLevel):
                guard case let .categoryClass(rhsCat, rhsLevel) = rhs else { return true }
                if lhsCat == rhsCat { return lhsLevel < rhsLevel }
                else { return lhsCat < rhsCat }
            case let .instrument(lhsCat):
                switch rhs {
                    case .categoryClass(_, _): return false
                    case let .instrument(rhsCat): return lhsCat < rhsCat
                    case .type(_, _): return true
                }
            case let .type(lhsType, lhsLevel):
                guard case let .type(rhsType, rhsLevel) = rhs else { return false }
                if lhsType == rhsType { return lhsLevel < rhsLevel }
                else { return lhsType < rhsType }
        }
    }
    
    /// A human-readable description of the rating.
    public var description: String {
        switch self {
            case let .categoryClass(categoryClass, level):
                return "\(categoryClass) (\(level))"
            case let .instrument(category): return "IFR-\(category)"
            case let .type(type, level): return "\(type) (\(level))"
        }
    }
    
    func descriptionForLevel(_ level: PilotLevel, centerlineThrustOnly: Bool) -> String {
        switch self {
            case let .categoryClass(categoryClass, ratingLevel):
                switch categoryClass {
                    case .airplaneMultiEngineLand, .airplaneMultiEngineSea:
                        if centerlineThrustOnly {
                            if ratingLevel == level { return "\(categoryClass)-C" }
                            else { return "\(categoryClass)-C (\(level))" }
                        } else {
                            if ratingLevel == level { return categoryClass.description }
                            else { return description }
                        }
                    default:
                        if ratingLevel == level { return categoryClass.description }
                        else { return description }
                }
            case let .type(type, ratingLevel):
                if ratingLevel == level { return type }
                else { return description }
            default: return description
        }
    }
}

/// An aircraft category rating for a flight instructor certificate.
public enum FlightInstructorCategory: Comparable, CustomStringConvertible, Sendable {

    /// CFI, airplane single-engine.
    case airplaneSingleEngine
    
    /// CFI, airplane multi-engine.
    case airplaneMultiEngine
    
    /// CFI, glider.
    case glider
    
    /// CFI, helicopter.
    case rotorcraftHelicopter
    
    /// CFI, gyroplane.
    case rotorcraftGyroplane
    
    /// CFI, powered lift.
    case poweredLift
    
    /// A human-readable abbreviation for the rating.
    public var description: String {
        switch self {
            case .airplaneSingleEngine: return "ASE"
            case .airplaneMultiEngine: return "AME"
            case .glider: return "GL"
            case .rotorcraftHelicopter: return "R-H"
            case .rotorcraftGyroplane: return "R-G"
            case .poweredLift: return "PL"
        }
    }
}

/// A rating on a flight instructor certificate.
public enum FlightInstructorRating: Comparable, Hashable, CustomStringConvertible, Sendable {

    /**
     A rating for an aircraft category.
     
     - Parameter category: The aircraft category.
     */
    case category(_ category: FlightInstructorCategory)
    
    /**
     A flight instructor instrument rating.
     
     - Parameter category: The aircraft category.
     */
    case instrument(_ category: InstrumentCategory)
    
    /// A sport pilot CFI rating.
    case sport
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
            case let .category(lhsCat):
                guard case let .category(rhsCat) = rhs else { return true }
                return lhsCat < rhsCat
            case let .instrument(lhsCat):
                switch rhs {
                    case .category(_): return false
                    case let .instrument(rhsCat): return lhsCat < rhsCat
                    case .sport: return true
                }
            case sport: return false
        }
    }
    
    /// A human-readable abbreviation for the rating.
    public var description: String {
        switch self {
            case let .category(category): return category.description
            case let .instrument(category): return "IFR-\(category.description)"
            case .sport: return "SPL"
        }
    }
}

/// A rating for an aircraft maintenance technician certificate.
public enum MechanicRating: Comparable, Hashable, CustomStringConvertible, Sendable {
    
    /// Airframe rating.
    case airframe
    
    /// Powerplant rating.
    case powerplant
    
    public var description: String {
        switch self {
            case .airframe: return "A"
            case .powerplant: return "P"
        }
    }
}

/// A rating for a ground instructor certificate.
public enum GroundInstructorRating: Comparable, Hashable, CustomStringConvertible, Sendable {

    /// Ground instructor, basic.
    case basic
    
    /// Ground instructor, advanced.
    case advanced
    
    /// Ground instructor, instrument.
    case instrument
    
    public var description: String {
        switch self {
            case .basic: return "B"
            case .advanced: return "A"
            case .instrument: return "I"
        }
    }
}

/// A rating for a light sport repairman certificate.
public enum RepairmanLightSportRating: Comparable, Hashable, CustomStringConvertible, Sendable {

    /// Maintenance rating.
    case maintenance
    
    /// Inspection rating.
    case inspection
    
    public var description: String {
        switch self {
            case .maintenance: return "M"
            case .inspection: return "I"
        }
    }
}

/// A certificate issued to a person by the FAA.
public enum Certificate: CustomStringConvertible, Sendable {

    /**
     A pilot certificate issued under FAR 61 subparts C through G.
     
     - Parameter level: The certificate level, which should be the highest level
                        of any pilot certificate rating.
     - Parameter ratings: The pilot ratings associated with this certificate.
     - Parameter centerlineThrustOnly: True if the pilot has a "centerline
                                       thrust only" limitation on their
                                       multiengine rating.
     */
    case pilot(level: PilotLevel, ratings: Set<PilotRating>, centerlineThrustOnly: Bool)
    
    /**
     A flight instructor certificate (CFI) issued under FAR 61 subpart H.
     
     - Parameter ratings: The instructor ratings associated with this
                          certificate.
     - Parameter expirationDate: The date this certificate expires.
     */
    case flightInstructor(ratings: Set<FlightInstructorRating>, expirationDate: DateComponents)
    
    /// An authorized aircraft instructor certificate.
    case authorizedAircraftInstructor
    
    /// A remote pilot (sUAS) certificate issued under FAR 107 subpart C.
    case remotePilot
    
    /**
     A ground instructor (GI) certificate issued under FAR 61 subpart I.
     
     - Parameter ratings: The ratings associated with this certificate.
     */
    case groundInstructor(ratings: Set<GroundInstructorRating>)
    
    /**
     A flight engineer (FE) certificate issued under FAR 63 subpart B.
     
     - Parameter ratings: The ratings associated with this certificate.
     */
    case flightEngineer(ratings: Set<FlightEngineerRating>)
    
    /// A flight engineer (special purpose -- lessee) certificate issued under
    /// FAR 63.23(b)(2).
    case flightEngineerLessee
    
    /**
     A flight engineer (special purpose -- foreign) certificate issued under
     FAR 63.23(b)(1).
     
     - Parameter ratings: The ratings associated with this certificate.
     */
    case flightEngineerForeign(ratings: Set<FlightEngineerRating>)
    
    /**
     An aviation maintenance technician (AMT) certificate issued under FAR 65
     subpart D.
     
     - Parameter ratings: The ratings associated with this certificate.
     */
    case mechanic(ratings: Set<MechanicRating>)
    
    /// A control tower operator certificate issued under FAR 65 subpart B.
    case controlTowerOperator
    
    /// A repairman certificate issued under FAR 65 subpart E.
    case repairman
    
    /// A repairman certificate (experimental aircraft builder) issued under
    /// FAR 65.104.
    case repairmanExperimental
    
    /// A repairman certificate (light sport aircraft) issued under FAR 65.107.
    case repairmanLightSport(ratings: Set<RepairmanLightSportRating>)
    
    /**
     A parachute rigger certificate issued under FAR 65 subpart F.
     
     - Parameter level: The certificate level (master or senior).
     - Parameter ratings: The ratings associated with this certificate.
     */
    case rigger(level: RiggerLevel, ratings: Set<RiggerRating>)
    
    /// An aircraft dispatcher certificate issued under FAR 65 subpart C.
    case dispatcher
    
    /// A flight navigator certificate issued under FAR 63 subpart C.
    case navigator
    
    /// A flight navigator (special purpose -- lessee) certificate issued under
    /// FAR 63.23(b)(2).
    case navigatorLessee
    
    /// A human-readable abbreviation of the certificate and ratings (if
    /// applicable).
    public var description: String {
        switch self {
            case let .pilot(level, ratings, centerlineThrustOnly):
                return "\(level) (\(ratings.sorted().map { $0.descriptionForLevel(level, centerlineThrustOnly: centerlineThrustOnly) }.joined(separator: ", ")))"
            case let .flightInstructor(ratings, _):
                return "CFI (\(ratings.sorted().map { $0.description }.joined(separator: ", ")))"
            case .authorizedAircraftInstructor: return "AAI"
            case .remotePilot: return "sUAS"
            case let .groundInstructor(ratings):
                return "\(ratings.sorted().map { $0.description }.joined())GI"
            case let .flightEngineer(ratings):
                return "FE (\(ratings.sorted().map { $0.description }.joined(separator: ", ")))"
            case .flightEngineerLessee: return "FE (lessee)"
            case let .flightEngineerForeign(ratings):
                return "FE (foreign, \(ratings.sorted().map { $0.description }.joined(separator: ", ")))"
            case let .mechanic(ratings):
                return "AMT (\(ratings.sorted().map { $0.description }.joined(separator: "&")))"
            case .controlTowerOperator: return "CTO"
            case .repairman: return "Repairman"
            case .repairmanExperimental: return "Repairman (EAB)"
            case let .repairmanLightSport(ratings):
                return "Repairman (LSA, \(ratings.sorted().map { $0.description }.joined(separator: "&")))"
            case let .rigger(level, ratings):
                return "Rigger (\(level), \(ratings.sorted().map { $0.descriptionForLevel(level) }.joined(separator: ", ")))"
            case .dispatcher: return "Dispatcher"
            case .navigator: return "FN"
            case .navigatorLessee: return "FN (lessee)"
        }
    }
}

/// A street address belonging to an airman.
public struct Address: CustomStringConvertible, Sendable {

    /// The first line of the street address.
    public var street1: String?
    
    /// The second line of the street address (unit number, etc.).
    public var street2: String?
    
    /// The city.
    public var city: String?
    
    /// The state code (e.g., CA).
    public var state: String?
    
    /// The ZIP or postal code.
    public var zipCode: String?
    
    /// The country.
    public var country: String?
    
    /// The administrative region.
    public var region: String?
    
    var isEmpty: Bool {
        street1 == nil && street2 == nil && city == nil && state == nil && zipCode == nil && country == nil && region == nil
    }
    
    /// The "[city], [state]" portion of the address, formatted as such.
    public var cityState: String? {
        if let city = city {
            if let state = state {
                return "\(city), \(state)"
            } else {
                return city
            }
        } else if let state = state {
            return state
        } else {
            return nil
        }
    }
    
    /// The "[city], [state]  [ZIP]" portion of the address, formatted as such.
    public var cityStateZip: String? {
        if let cityState = cityState {
            if let zipCode = zipCode {
                return "\(cityState)  \(zipCode)"
            } else {
                return cityState
            }
        } else  if let zipCode = zipCode {
            return zipCode
        } else {
            return nil
        }
    }
    
    /// The full address in human-readable format.
    public var description: String {
        return [street1, street2, cityStateZip, country].compactMap { $0 }.joined(separator: "\n")
    }
}

/// Classes for aviation medical certificates.
public enum MedicalClass: CustomStringConvertible, Sendable {

    /// A first-class medical certificate issued under FAR 67 subpart B.
    case first
    
    /// A second-class medical certificate issued under FAR 67 subpart C.
    case second

    /// A third-class medical certificate issued under FAR 67 subpart D.
    case third
    
    /// A human-readable description for the certificate class.
    public var description: String {
        switch self {
            case .first: return "1st Class"
            case .second: return "2nd Class"
            case .third: return "3rd Class"
        }
    }
}

/// An aviation medical certificate issued under FAR 67.
public enum Medical: CustomStringConvertible, Sendable {

    /**
     A first-, second-, or third-class medical issued under FAR 67 subparts B
     through D.
     
     - Parameter class: The class of medical certificate.
     - Parameter date: The date of issuance.
     - Parameter expirationDate: The date the medical completely expires.
     */
    case FAA(_ `class`: MedicalClass, date: DateComponents, expirationDate: DateComponents?)
    
    /**
     A BasicMed qualification under FAR 68.
     
     - Parameter courseDate: The date that the FAR 68.3 course was completed.
     - Parameter expirationDate: The date the qualification expires.
     - Parameter CMECDate: The date the comprehensive medical examination
                           checklist was last completed.
     */
    case basicMed(courseDate: DateComponents, expirationDate: DateComponents?, CMECDate: DateComponents?)
    
    /// A human-readable description of the certificate.
    public var description: String {
        switch self {
            case let .FAA(`class`, _, _): return `class`.description
            case .basicMed(_, _, _): return "BasicMed"
        }
    }
}

/// A person holding one or more FAA-issued certificates.
public struct Airman: Identifiable, CustomDebugStringConvertible, Sendable {

    /// A unique, FAA-assigned identifier for the airman.
    public let id: String
    
    /// The airman's given or first name.
    public var firstName: String?
    
    /// The airman's family or last name.
    public var lastName: String?
    
    /// The airman's street address.
    public var address: Address?
    
    /// The medical certificate held by the airman, if any.
    public var medical: Medical?
    
    /// The FAA certificates held by the airman.
    public var certificates: Array<Certificate> = []
    
    init(id: String, firstName: String? = nil, lastName: String? = nil, address: Address? = nil, medical: Medical? = nil, certificates: Array<Certificate> = []) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.medical = medical
        self.certificates = certificates
    }
    
    /// The airman's full name.
    public var name: String? {
        if let first = firstName {
            if let last = lastName {
                return "\(first) \(last)"
            } else {
                return first
            }
        } else {
            if let last = lastName {
                return last
            } else {
                return nil
            }
        }
    }
    
    public var debugDescription: String {
        "Airman(\(id): \(name ?? "<no name>"))"
    }
    
    func mergedWith(_ other: Airman) -> Airman {
        var newAirman = Airman(id: id)
        newAirman.firstName = other.firstName ?? firstName
        newAirman.lastName = other.lastName ?? lastName
        newAirman.medical = other.medical ?? medical
        newAirman.certificates = other.certificates + certificates
        return newAirman
    }
}
