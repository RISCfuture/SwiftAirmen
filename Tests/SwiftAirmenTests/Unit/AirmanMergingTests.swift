import Foundation
@testable import SwiftAirmen
import Testing

@Suite("Airman Merging Tests")
struct AirmanMergingTests {

    @Test("Merge two Airman records preferring non-nil values from newer record")
    func mergePreferringNewer() {
        let oldAirman = Airman(
            id: "A0000001",
            firstName: "John",
            lastName: "Doe",
            address: Address(
                street1: "123 Old St",
                street2: nil,
                city: "OldCity",
                state: "OC",
                zipCode: "00000",
                country: "USA",
                region: "OL"
            ),
            medical: .FAA(.third, date: DateComponents(year: 2022, month: 1, day: 1), expirationDate: nil),
            certificates: [.pilot(level: .private, ratings: [], centerlineThrustOnly: false)]
        )

        let newAirman = Airman(
            id: "A0000001",
            firstName: "Johnny",
            lastName: "Doe Jr",
            address: Address(
                street1: "456 New Ave",
                street2: "Apt 2B",
                city: "NewCity",
                state: "NC",
                zipCode: "11111",
                country: "USA",
                region: "NW"
            ),
            medical: .FAA(.first, date: DateComponents(year: 2024, month: 1, day: 1), expirationDate: DateComponents(year: 2026, month: 1, day: 1)),
            certificates: [.pilot(level: .commercial, ratings: [.instrument(.airplane)], centerlineThrustOnly: false)]
        )

        let merged = oldAirman.mergedWith(newAirman)

        // Should prefer newer values
        #expect(merged.firstName == "Johnny")
        #expect(merged.lastName == "Doe Jr")
        #expect(merged.address?.street1 == "456 New Ave")
        #expect(merged.address?.street2 == "Apt 2B")
        #expect(merged.address?.city == "NewCity")

        if case let .FAA(medClass, date, _) = merged.medical {
            #expect(medClass == .first)
            #expect(date.year == 2024)
        } else {
            Issue.record("Expected FAA medical")
        }
    }

    @Test("Combine certificates from both records without duplicates")
    func combineCertificatesWithoutDuplicates() {
        let airman1 = Airman(
            id: "A0000001",
            firstName: "John",
            lastName: "Doe",
            certificates: [
                .pilot(level: .private, ratings: [.categoryClass(.airplaneSingleEngineLand, level: .private)], centerlineThrustOnly: false),
                .flightInstructor(ratings: [.category(.airplaneSingleEngine)], expirationDate: DateComponents(year: 2025, month: 12, day: 31))
            ]
        )

        let airman2 = Airman(
            id: "A0000001",
            firstName: "John",
            lastName: "Doe",
            certificates: [
                .pilot(level: .private, ratings: [.categoryClass(.airplaneSingleEngineLand, level: .private)], centerlineThrustOnly: false), // Duplicate
                .mechanic(ratings: [.airframe, .powerplant]) // New
            ]
        )

        let merged = airman1.mergedWith(airman2)

        // Should have 3 certificates (pilot, CFI, mechanic) - no duplicate pilot
        #expect(merged.certificates.count == 3)

        let hasPilot = merged.certificates.contains { cert in
            if case .pilot = cert { return true }
            return false
        }
        #expect(hasPilot)

        let hasCFI = merged.certificates.contains { cert in
            if case .flightInstructor = cert { return true }
            return false
        }
        #expect(hasCFI)

        let hasMechanic = merged.certificates.contains { cert in
            if case .mechanic = cert { return true }
            return false
        }
        #expect(hasMechanic)
    }

    @Test("Preserve original data when merging with empty record")
    func mergeWithEmptyRecord() {
        let fullAirman = Airman(
            id: "A0000001",
            firstName: "John",
            lastName: "Doe",
            address: Address(
                street1: "123 Main St",
                street2: nil,
                city: "Seattle",
                state: "WA",
                zipCode: "98101",
                country: "USA",
                region: "NW"
            ),
            medical: .basicMed(
                courseDate: DateComponents(year: 2023, month: 6, day: 1),
                expirationDate: DateComponents(year: 2025, month: 6, day: 1),
                CMECDate: DateComponents(year: 2023, month: 5, day: 15)
            ),
            certificates: [
                .pilot(level: .commercial, ratings: [
                    .categoryClass(.airplaneMultiEngineLand, level: .commercial),
                    .instrument(.airplane)
                ], centerlineThrustOnly: false)
            ]
        )

        let emptyAirman = Airman(
            id: "A0000001",
            firstName: nil,
            lastName: nil,
            address: nil,
            medical: nil,
            certificates: []
        )

        let merged = fullAirman.mergedWith(emptyAirman)

        // Should preserve all original data
        #expect(merged.firstName == "John")
        #expect(merged.lastName == "Doe")
        #expect(merged.address?.street1 == "123 Main St")
        #expect(merged.address?.city == "Seattle")

        if case .basicMed = merged.medical {
            // Expected
        } else {
            Issue.record("Expected BasicMed to be preserved")
        }

        #expect(merged.certificates.count == 1)
    }

    @Test("Merge partial records correctly")
    func mergePartialRecords() {
        let partial1 = Airman(
            id: "A0000001",
            firstName: "John",
            lastName: nil,
            address: Address(
                street1: "123 Main St",
                street2: nil,
                city: nil,
                state: nil,
                zipCode: nil,
                country: nil,
                region: nil
            ),
            medical: nil,
            certificates: []
        )

        let partial2 = Airman(
            id: "A0000001",
            firstName: nil,
            lastName: "Doe",
            address: Address(
                street1: nil,
                street2: nil,
                city: "Seattle",
                state: "WA",
                zipCode: "98101",
                country: nil,
                region: nil
            ),
            medical: .FAA(.second, date: DateComponents(year: 2024, month: 1, day: 1), expirationDate: nil),
            certificates: [.remotePilot]
        )

        let merged = partial1.mergedWith(partial2)

        // Should combine both partial records
        #expect(merged.firstName == "John") // From partial1
        #expect(merged.lastName == "Doe") // From partial2
        #expect(merged.address?.street1 == nil) // partial2's nil overwrites partial1's value
        #expect(merged.address?.city == "Seattle") // From partial2
        #expect(merged.address?.state == "WA") // From partial2

        if case .FAA(.second, _, _) = merged.medical {
            // Expected
        } else {
            Issue.record("Expected FAA second-class medical from partial2")
        }

        #expect(merged.certificates.count == 1)
        #expect(merged.certificates.first == .remotePilot)
    }

    @Test("Address isEmpty property")
    func addressIsEmpty() {
        let emptyAddress = Address(
            street1: nil,
            street2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            region: nil
        )
        #expect(emptyAddress.isEmpty == true)

        let partialAddress = Address(
            street1: "123 Main St",
            street2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            region: nil
        )
        #expect(partialAddress.isEmpty == false)

        let fullAddress = Address(
            street1: "123 Main St",
            street2: "Apt 2B",
            city: "Seattle",
            state: "WA",
            zipCode: "98101",
            country: "USA",
            region: "NW"
        )
        #expect(fullAddress.isEmpty == false)
    }

    @Test("Address formatting methods")
    func addressFormatting() {
        let address = Address(
            street1: "123 Main St",
            street2: "Apt 2B",
            city: "Seattle",
            state: "WA",
            zipCode: "98101",
            country: "USA",
            region: "NW"
        )

        #expect(address.cityState == "Seattle, WA")
        #expect(address.cityStateZip == "Seattle, WA  98101")

        // Test with missing components
        let partialAddress = Address(
            street1: nil,
            street2: nil,
            city: "London",
            state: nil,
            zipCode: "SW1A 1AA",
            country: "UK",
            region: nil
        )

        #expect(partialAddress.cityState == "London")
        #expect(partialAddress.cityStateZip == "London  SW1A 1AA")

        // Test with only state
        let stateOnly = Address(
            street1: nil,
            street2: nil,
            city: nil,
            state: "CA",
            zipCode: nil,
            country: nil,
            region: nil
        )

        #expect(stateOnly.cityState == "CA")
        #expect(stateOnly.cityStateZip == "CA")
    }
}
