import Foundation
import Dispatch
import CSV

/**
 Parses an airman certification database into memory. The database must be
 downloaded
 [from the FAA website](https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download/)
 in CSV format and stored, unarchived, in a
 directory somewhere accessible. The names of the CSV files must not be changed.
 */
public class Parser {
    /// The directory that the parser will look for CSV files in.
    public let directory: URL
    
    /// The GCD queue that will be used for parsing operations.
    public var queue = DispatchQueue(label: "codes.tim.SwiftAirmen", qos: .background, attributes: [.concurrent])
    private let airmenSemaphore = DispatchSemaphore(value: 1)
    
    private static let pilotBasicFile = "PILOT_BASIC.csv"
    private static let nonpilotBasicFile = "NONPILOT_BASIC.csv"
    private static let pilotCertFile = "PILOT_CERT.csv"
    private static let nonPilotCertFile = "NONPILOT_CERT.csv"
    
    /// An estimation of the amount of work required to parse the
    /// `PILOT_BASIC.CSV` file. Used by `Progress`.
    public var pilotBasicWorkUnits: Int64 = 569237
    
    /// An estimation of the amount of work required to parse the
    /// `NONPILOT_BASIC.CSV` file. Used by `Progress`.
    public var nonpilotBasicWorkUnits: Int64 = 389756
    
    /// An estimation of the amount of work required to parse the
    /// `PILOT_CERT.CSV` file. Used by `Progress`.
    public var pilotCertWorkUnits: Int64 = 674597*36
    
    /// An estimation of the amount of work required to parse the
    /// `NONPILOT_CERT.CSV` file. Used by `Progress`.
    public var nonpilotCertWorkUnits: Int64 = 403499
    
    /// An estimation of the amount of work required to parse the
    /// `PILOT_BASIC.CSV` file. Used by `Progress`.
    private var mergeWorkUnits: Int64 = 2037089
    
    private var totalWorkUnits: Int64 {
        pilotBasicWorkUnits + nonpilotBasicWorkUnits + pilotCertWorkUnits + nonpilotCertWorkUnits + mergeWorkUnits
    }
    
    /**
     Creates a new instance.
     
     - Parameter directory: The directory containing the CSV files.
     */
    public init(directory: URL) {
        self.directory = directory
    }
    
    /**
     Parses all records in all CSV files within the directory. Rows are parsed
     across all four database files and combined into individual `Airmen`
     records.
     
     Execution is asynchronous and occurs on `queue`.
     
     - Parameter callback: Code to execute once parsing is complete.
     - Parameter airmen: A dictionary mapping airmen record IDs to `Airmen`
                         records.
     - Parameter errorCallback: Code to execute when any parsing error occurs.
                                Parsing errors do not cause parsing to abort.
     - Parameter error: The parsing error that occurred.
     - Returns: A `Progress` instance that tracks overall parsing progress.
     */
    @discardableResult public func parse(callback: @escaping (_ airmen: Dictionary<String, Airman>) -> Void, errorCallback: @escaping (_ error: Error) -> Void) throws -> Progress {
        let group = DispatchGroup()
        let db = AirmanDatabase()
        
        let progress = Progress(totalUnitCount: totalWorkUnits)
        
        queue.async(group: group) {
            do {
                var subprogress: Progress? = Progress(totalUnitCount: 0, parent: progress, pendingUnitCount: self.pilotBasicWorkUnits)
                db.append(airmen: try self.parsePilotBasic(errorCallback: errorCallback, progress: &subprogress))
            } catch let error {
                errorCallback(error)
            }
        }
        
        queue.async(group: group) {
            do {
                var subprogress: Progress? = Progress(totalUnitCount: 0, parent: progress, pendingUnitCount: self.nonpilotBasicWorkUnits)
                db.append(airmen: try self.parseNonPilotBasic(errorCallback: errorCallback, progress: &subprogress))
            } catch let error {
                errorCallback(error)
            }
        }
        
        queue.async(group: group) {
            do {
                var subprogress: Progress? = Progress(totalUnitCount: 0, parent: progress, pendingUnitCount: self.pilotCertWorkUnits)
                db.append(airmen: try self.parsePilotCert(errorCallback: errorCallback, progress: &subprogress))
            } catch let error {
                errorCallback(error)
            }
        }
        
        queue.async(group: group) {
            do {
                var subprogress: Progress? = Progress(totalUnitCount: 0, parent: progress, pendingUnitCount: self.nonpilotCertWorkUnits)
                db.append(airmen: try self.parseNonPilotCert(errorCallback: errorCallback, progress: &subprogress))
            } catch let error {
                errorCallback(error)
            }
        }
        
        group.notify(queue: queue) {
            progress.addChild(db.merged(callback: callback), withPendingUnitCount: self.mergeWorkUnits)
        }
        
        return progress
    }
    
    /**
     Parses the `PILOT_BASIC.CSV` file only. Execution is synchronous.
     
     - Parameter errorCallback: Called when an error occurs during parsing.
                                Errors do not abort parsing.
     - Parameter error: The parse error that occurred.
     - Parameter progress: An optional `Progress` instance that can be used to
                           track the progress of the parse operation in a
                           separate thread. Pass `nil` if you do not need to
                           track progress.
     - Returns: The parsed airmen records.
     */
    public func parsePilotBasic(errorCallback: @escaping (_ error: Error) -> Void, progress: inout Progress?) throws -> Array<Airman> {
        return try parseBasic(filename: Self.pilotBasicFile, errorCallback: errorCallback, progress: &progress)
    }
    
    /**
     Parses the `NONPILOT_BASIC.CSV` file only. Execution is synchronous.
     
     - Parameter errorCallback: Called when an error occurs during parsing.
     Errors do not abort parsing.
     - Parameter error: The parse error that occurred.
     - Parameter progress: An optional `Progress` instance that can be used to
     track the progress of the parse operation in a
     separate thread. Pass `nil` if you do not need to
     track progress.
     - Returns: The parsed airmen records.
     */
    public func parseNonPilotBasic(errorCallback: @escaping (_ error: Error) -> Void, progress: inout Progress?) throws -> Array<Airman> {
        return try parseBasic(filename: Self.nonpilotBasicFile, errorCallback: errorCallback, progress: &progress)
    }
    
    /**
     Parses the `PILOT_CERT.CSV` file only. Execution is synchronous.
     
     - Parameter errorCallback: Called when an error occurs during parsing.
     Errors do not abort parsing.
     - Parameter error: The parse error that occurred.
     - Parameter progress: An optional `Progress` instance that can be used to
     track the progress of the parse operation in a
     separate thread. Pass `nil` if you do not need to
     track progress.
     - Returns: The parsed airmen records.
     */
    public func parsePilotCert(errorCallback: @escaping (_ error: Error) -> Void, progress: inout Progress?) throws -> Array<Airman> {
        let url = directory.appendingPathComponent(Self.pilotCertFile)
        
        progress?.totalUnitCount = try countLines(in: url)
        progress?.completedUnitCount = 0
        
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        var airmen = Array<Airman>()
        while true {
            do {
                guard let row = try parser.next(as: PilotCertRow.self) else { break }
                airmen.append(try parsePilotCertRow(row))
                progress?.completedUnitCount += 1
            } catch let error {
                errorCallback(error)
            }
        }
        
        return airmen
    }
    
    /**
     Parses the `NONPILOT_CERT.CSV` file only. Execution is synchronous.
     
     - Parameter errorCallback: Called when an error occurs during parsing.
     Errors do not abort parsing.
     - Parameter error: The parse error that occurred.
     - Parameter progress: An optional `Progress` instance that can be used to
     track the progress of the parse operation in a
     separate thread. Pass `nil` if you do not need to
     track progress.
     - Returns: The parsed airmen records.
     */
    public func parseNonPilotCert(errorCallback: @escaping (_ error: Error) -> Void, progress: inout Progress?) throws -> Array<Airman> {
        let url = directory.appendingPathComponent(Self.nonPilotCertFile)
        
        progress?.totalUnitCount = try countLines(in: url)
        progress?.completedUnitCount = 0
        
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        var airmen = Array<Airman>()
        while true {
            do {
                guard let row = try parser.next(as: NonPilotCertRow.self) else { break }
                airmen.append(try parseNonPilotCertRow(row))
                progress?.completedUnitCount += 1
            } catch let error {
                errorCallback(error)
            }
        }
        
        return airmen
    }
    
    private func parseBasic(filename: String, errorCallback: @escaping (Error) -> Void, progress: inout Progress?) throws -> Array<Airman> {
        let url = directory.appendingPathComponent(filename)
        
        progress?.totalUnitCount = try countLines(in: url)
        progress?.completedUnitCount = 0
        
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        var airmen = Array<Airman>()
        while true {
            do {
                guard let row = try parser.next(as: AirmanBasicRow.self) else { break }
                airmen.append(try parseBasicRow(row))
                progress?.completedUnitCount += 1
            } catch let error {
                errorCallback(error)
            }
        }
        
        return airmen
    }
    
    private func parseBasicRow(_ row: AirmanBasicRow) throws -> Airman {
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
        if (airman.address!.isEmpty) { airman.address = nil }
        
        if let medClass = row.medicalClass {
            guard let medicalDate = row.medicalDate else {
                throw Errors.medicalWithoutDate(uniqueID: row.uniqueID)
            }
            
            switch medClass {
                case .first:
                    airman.medical = .FAA(.first,
                                          date: medicalDate,
                                          expirationDate: row.medicalExpirationDate)
                case .second:
                    airman.medical = .FAA(.second,
                                          date: medicalDate,
                                          expirationDate: row.medicalExpirationDate)
                case .third:
                    airman.medical = .FAA(.third,
                                          date: medicalDate,
                                          expirationDate: row.medicalExpirationDate)
                case .unknown8:
                    airman.medical = nil
            }
        } else {
            if let basicMedCourseDate = row.basicMedCourseDate {
                airman.medical = .basicMed(courseDate: basicMedCourseDate,
                                           expirationDate: row.medicalExpirationDate,
                                           CMECDate: row.basicMedCMECDate)
            } else {
                airman.medical = nil
            }
        }
        
        return airman
    }
    
    private func parsePilotCertRow(_ row: PilotCertRow) throws -> Airman {
        var airman = Airman(id: row.uniqueID)
        airman.firstName = row.firstName
        airman.lastName = row.lastName
        
        switch row.type {
            case .pilot:
                guard let rowLevel = row.level else {
                    throw Errors.levelNotGiven(uniqueID: row.uniqueID)
                }
                guard case let .pilot(rowPilotLevel) = rowLevel else {
                    fatalError("Certificate type and level mismatch")
                }
                let level = self.convertLevel(rowPilotLevel)
                
                var ratings = Set<PilotRating>()
                var centerlineThrust = false
                for rowRating in row.ratings {
                    guard case let .pilot(rowPilotRating, ratingLevel) = rowRating else {
                        fatalError("Certificate and rating type mismatch")
                    }
                    
                    switch rowPilotRating {
                        case .airplaneSingleEngineLand:
                            ratings.insert(.categoryClass(.airplaneSingleEngineLand, level: self.convertLevel(ratingLevel)))
                        case .airplaneSingleEngineSea:
                            ratings.insert(.categoryClass(.airplaneSingleEngineSea, level: self.convertLevel(ratingLevel)))
                        case .airplaneMultiEngineLand:
                            ratings.insert(.categoryClass(.airplaneMultiEngineLand, level: self.convertLevel(ratingLevel)))
                        case .airplaneMultiEngineSea:
                            ratings.insert(.categoryClass(.airplaneMultiEngineSea, level: self.convertLevel(ratingLevel)))
                        case .glider:
                            ratings.insert(.categoryClass(.glider, level: self.convertLevel(ratingLevel)))
                        case .rotorcraftHelicopter:
                            ratings.insert(.categoryClass(.rotorcraftHelicopter, level: self.convertLevel(ratingLevel)))
                        case .instrumentAirplane:
                            ratings.insert(.instrument(.airplane))
                        case .instrumentAirplaneHelicopter:
                            ratings.insert(.instrument(.airplane))
                            ratings.insert(.instrument(.helicopter))
                        case .instrumentHelicopter:
                            ratings.insert(.instrument(.helicopter))
                        case .rotorcraftGyroplane:
                            ratings.insert(.categoryClass(.rotorcraftGyroplane, level: self.convertLevel(ratingLevel)))
                        case .ltaBalloon:
                            ratings.insert(.categoryClass(.lighterThanAirBalloon, level: self.convertLevel(ratingLevel)))
                        case .amelCenterlineThrust:
                            ratings.insert(.categoryClass(.airplaneMultiEngineLand, level: self.convertLevel(ratingLevel)))
                            centerlineThrust = true
                        case .ltaAirship:
                            ratings.insert(.categoryClass(.lighterThanAirAirship, level: self.convertLevel(ratingLevel)))
                        case .rotorcraftHelicopterGyroplane:
                            ratings.insert(.categoryClass(.rotorcraftHelicopter, level: self.convertLevel(ratingLevel)))
                            ratings.insert(.categoryClass(.rotorcraftGyroplane, level: self.convertLevel(ratingLevel)))
                        case .poweredLift:
                            ratings.insert(.categoryClass(.poweredLift, level: self.convertLevel(ratingLevel)))
                        case .instrumentPoweredLift:
                            ratings.insert(.instrument(.poweredLift))
                        case .sport: break
                    }
                }
                
                for rowRating in row.typeRatings {
                    ratings.insert(.type(rowRating.type, level: self.convertLevel(rowRating.level)))
                }
                
                airman.certificates.append(.pilot(level: level, ratings: ratings, centerlineThrustOnly: centerlineThrust))
            case .authorizedAircraftInstructor:
                airman.certificates.append(.authorizedAircraftInstructor)
            case .flightInstructor:
                var ratings = Set<FlightInstructorRating>()
                for rowRating in row.ratings {
                    guard case let .flightInstructor(rowCFIRating) = rowRating else {
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
                for rowRating in row.ratings {
                    guard case let .flightEngineer(engRating) = rowRating else {
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
                for rowRating in row.ratings {
                    guard case let .flightEngineerForeign(engRating) = rowRating else {
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
    
    private func parseNonPilotCertRow(_ row: NonPilotCertRow) throws -> Airman {
        var airman = Airman(id: row.uniqueID)
        airman.firstName = row.firstName
        airman.lastName = row.lastName
        
        switch row.type {
            case .groundInstructor:
                var ratings = Set<GroundInstructorRating>()
                for rowRating in row.ratings {
                    guard case let .groundInstructor(instructorRating) = rowRating else {
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
                for rowRating in row.ratings {
                    guard case let .mechanic(mechRating) = rowRating else {
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
                for rowRating in row.ratings {
                    guard case let .repairmanLightSport(repairmanRating) = rowRating else {
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
                guard let rowLevel = row.level else {
                    throw Errors.levelNotGiven(uniqueID: row.uniqueID)
                }
                guard case let .rigger(riggerLevel) = rowLevel else {
                    fatalError("Certificate type and level mismatch")
                }
                switch riggerLevel {
                    case .master: level = .master
                    case .senior: level = .senior
                }
                
                var ratings = Set<RiggerRating>()
                for rowRating in row.ratings {
                    guard case let .rigger(riggerRating, riggerLevel) = rowRating else {
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
    
    private func countLines(in url: URL) throws -> Int64 {
        let data = try String(contentsOf: url, encoding: .ascii)
        var count: Int64 = 0
        data.enumerateLines { _, _ in count += 1 }
        return count
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
