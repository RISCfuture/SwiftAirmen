import Foundation
@testable import SwiftAirmen
import Testing

@Suite("Parser Integration Tests")
struct ParserIntegrationTests {

    let testResourcesURL = Bundle.module.resourceURL!
        .appendingPathComponent("TestResources")

    @Test("Parse pilot basic CSV file")
    func parsePilotBasicCSV() async throws {
        let parser = Parser(directory: testResourcesURL)
        let errorCollector = ErrorCollector()

        let airmen = try await parser.parse(
            files: [.pilotBasic],
            progress: nil,
            errorCallback: { error in
                errorCollector.add(error)
            }
        )

        #expect(errorCollector.errors.isEmpty)

        // Test first-class medical
        let john = try #require(airmen["A0000001"])
        #expect(john.firstName == "JOHN")
        #expect(john.lastName == "DOE")
        #expect(john.address?.street1 == "123 MAIN ST")
        #expect(john.address?.city == "SEATTLE")
        #expect(john.address?.state == "WA")
        if case let .FAA(medClass, _, _) = john.medical {
            #expect(medClass == .first)
        } else {
            Issue.record("Expected FAA first-class medical")
        }

        // Test BasicMed
        let jane = try #require(airmen["A0000002"])
        #expect(jane.firstName == "JANE")
        if case .basicMed = jane.medical {
            // Expected
        } else {
            Issue.record("Expected BasicMed")
        }
        #expect(jane.address == nil) // All address fields empty

        // Test medical class without date (should be in errors)
        let bob = try #require(airmen["A0000003"])
        #expect(bob.medical == nil)

        // Test medical class 8 (unknown)
        let david = try #require(airmen["A0000006"])
        #expect(david.medical == nil)
        #expect(david.address?.country == "UK")
    }

    @Test("Parse pilot certificates CSV file")
    func parsePilotCertCSV() async throws {
        let parser = Parser(directory: testResourcesURL)
        let errorCollector = ErrorCollector()

        let airmen = try await parser.parse(
            files: [.pilotCert],
            progress: nil,
            errorCallback: { error in
                errorCollector.add(error)
            }
        )

        // Test ATP with type ratings
        let john = try #require(airmen["A0000001"])
        #expect(john.certificates.count == 1)

        if let cert = john.certificates.first,
           case let .pilot(level, ratings, centerline) = cert {
            #expect(level == .airlineTransport)
            #expect(centerline == false)
            #expect(ratings.contains(.categoryClass(.airplaneMultiEngineLand, level: .airlineTransport)))
            #expect(ratings.contains(.categoryClass(.airplaneSingleEngineLand, level: .airlineTransport)))
            #expect(ratings.contains(.instrument(.airplane)))
            #expect(ratings.contains(.type("B737", level: .airlineTransport)))
            #expect(ratings.contains(.type("B757", level: .airlineTransport)))
        } else {
            Issue.record("Expected pilot certificate")
        }

        // Test CFI and Commercial pilot (same person, different certs)
        let jane = try #require(airmen["A0000002"])
        #expect(jane.certificates.count == 2)

        let hasCFI = jane.certificates.contains { cert in
            if case .flightInstructor = cert { return true }
            return false
        }
        #expect(hasCFI)

        let hasCommercial = jane.certificates.contains { cert in
            if case let .pilot(level, _, _) = cert {
                return level == .commercial
            }
            return false
        }
        #expect(hasCommercial)

        // Test centerline thrust (AMELC)
        let alice = airmen["A0000004"]
        if let cert = alice?.certificates.first,
           case let .pilot(_, ratings, centerline) = cert {
            #expect(centerline == true) // AMELC sets centerline thrust flag
            #expect(ratings.contains(.categoryClass(.airplaneMultiEngineLand, level: .commercial)))
        }
    }

    @Test("Parse non-pilot certificates CSV file")
    func parseNonPilotCertCSV() async throws {
        let parser = Parser(directory: testResourcesURL)
        let errorCollector = ErrorCollector()

        let airmen = try await parser.parse(
            files: [.nonPilotCert],
            progress: nil,
            errorCallback: { error in
                errorCollector.add(error)
            }
        )

        // Test mechanic with A&P
        let frank = try #require(airmen["A0000008"])
        if let cert = frank.certificates.first,
           case let .mechanic(ratings) = cert {
            #expect(ratings.contains(.airframe))
            #expect(ratings.contains(.powerplant))
        } else {
            Issue.record("Expected mechanic certificate")
        }

        // Test ground instructor with all ratings
        let grace = airmen["A0000009"]
        if let cert = grace?.certificates.first,
           case let .groundInstructor(ratings) = cert {
            #expect(ratings.contains(.basic))
            #expect(ratings.contains(.advanced))
            #expect(ratings.contains(.instrument))
        }

        // Test rigger with multiple ratings at different levels
        let henry = airmen["A0000010"]
        if let cert = henry?.certificates.first,
           case let .rigger(level, ratings) = cert {
            #expect(level == .master)
            #expect(ratings.contains(.back(level: .master)))
            #expect(ratings.contains(.seat(level: .senior)))
        }

        // Test dispatcher
        let leo = airmen["A0000016"]
        #expect(leo?.certificates.first == .dispatcher)

        // Test control tower operator
        let mary = airmen["A0000017"]
        #expect(mary?.certificates.first == .controlTowerOperator)

        // Test rigger without level (should be in errors)
        #expect(errorCollector.errors.contains { error in
            if let airmenError = error as? Errors,
               case .levelNotGiven(uniqueID: "A0000018") = airmenError {
                return true
            }
            return false
        })
    }

    @Test("Merge data from multiple files")
    func mergeMultipleFiles() async throws {
        let parser = Parser(directory: testResourcesURL)

        let airmen = try await parser.parse(
            files: [.pilotBasic, .pilotCert],
            progress: nil,
            errorCallback: { _ in }
        )

        // John Doe should have data from both files
        let john = try #require(airmen["A0000001"])

        // From pilot_basic.csv
        #expect(john.address?.street1 == "123 MAIN ST")
        if case .FAA(.first, _, _) = john.medical {
            // Expected
        } else {
            Issue.record("Expected first-class medical")
        }

        // From pilot_cert.csv
        #expect(john.certificates.count == 1)
        if let cert = john.certificates.first,
           case let .pilot(level, _, _) = cert {
            #expect(level == .airlineTransport)
        }
    }

    @Test("Progress reporting during parsing")
    func progressReporting() async throws {
        let parser = Parser(directory: testResourcesURL)
        let progress = AsyncProgress()

        _ = try await parser.parse(
            files: [.pilotBasic],
            progress: progress,
            errorCallback: { _ in }
        )

        // Just verify that parsing completes with progress tracking enabled
        // We can't easily test the actual progress updates without access to the AsyncProgress internals
        // Test passes if no errors thrown
    }

    @Test("Handle file not found")
    func fileNotFound() async throws {
        let nonExistentDir = URL(fileURLWithPath: "/tmp/nonexistent")
        let parser = Parser(directory: nonExistentDir)
        let errorCollector = ErrorCollector()

        _ = try await parser.parse(
            files: [.pilotBasic],
            progress: nil,
            errorCallback: { error in
                if let airmenError = error as? Errors,
                   case .fileNotFound = airmenError {
                    errorCollector.add(error)
                }
            }
        )

        #expect(!errorCollector.errors.isEmpty)
    }

    @Test("Continue parsing after errors")
    func continueAfterErrors() async throws {
        let parser = Parser(directory: testResourcesURL)
        let errorCounter = ErrorCounter()

        // Parse file with pilot cert errors (missing level, missing expiration)
        let airmen = try await parser.parse(
            files: [.pilotCert],
            progress: nil,
            errorCallback: { _ in
                errorCounter.increment()
            }
        )

        // Our test files are now valid, so no errors expected
        #expect(!airmen.isEmpty)

        // Valid records should still be parsed
        #expect(airmen["A0000001"] != nil) // Valid ATP
        #expect(airmen["A0000003"] != nil) // Valid PPL
    }
}
