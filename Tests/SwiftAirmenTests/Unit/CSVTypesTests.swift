import Foundation
@testable import SwiftAirmen
import Testing

@Suite("CSV Types Tests")
struct CSVTypesTests {

    @Test("Parse MMDDYY date format with century logic")
    func parseMMDDYY() {
        // Years 50-99 should be 1950-1999
        let date1950 = DateComponents(csvString: "011550")
        #expect(date1950?.year == 1950)
        #expect(date1950?.month == 1)
        #expect(date1950?.day == 15)

        let date1999 = DateComponents(csvString: "123199")
        #expect(date1999?.year == 1999)
        #expect(date1999?.month == 12)
        #expect(date1999?.day == 31)

        // Years 00-49 should be 2000-2049
        let date2000 = DateComponents(csvString: "010100")
        #expect(date2000?.year == 2000)
        #expect(date2000?.month == 1)
        #expect(date2000?.day == 1)

        let date2024 = DateComponents(csvString: "063024")
        #expect(date2024?.year == 2024)
        #expect(date2024?.month == 6)
        #expect(date2024?.day == 30)

        let date2049 = DateComponents(csvString: "123149")
        #expect(date2049?.year == 2049)
        #expect(date2049?.month == 12)
        #expect(date2049?.day == 31)
    }

    @Test("Parse MMDDYYYY date format")
    func parseMMDDYYYY() {
        let date1995 = DateComponents(csvString: "07041995")
        #expect(date1995?.year == 1995)
        #expect(date1995?.month == 7)
        #expect(date1995?.day == 4)

        let date2025 = DateComponents(csvString: "01012025")
        #expect(date2025?.year == 2025)
        #expect(date2025?.month == 1)
        #expect(date2025?.day == 1)

        let date2100 = DateComponents(csvString: "12312100")
        #expect(date2100?.year == 2100)
        #expect(date2100?.month == 12)
        #expect(date2100?.day == 31)
    }

    @Test("Handle invalid date formats")
    func invalidDateFormats() {
        // Too short
        #expect(DateComponents(csvString: "1234") == nil)

        // Too long (but not 8 characters)
        #expect(DateComponents(csvString: "1234567") == nil)
        #expect(DateComponents(csvString: "123456789") == nil)

        // Non-numeric characters
        #expect(DateComponents(csvString: "ABCDEF") == nil)
        #expect(DateComponents(csvString: "01-01-24") == nil)
        #expect(DateComponents(csvString: "01/01/24") == nil)

        // Empty string
        #expect(DateComponents(csvString: "") == nil)

        // Whitespace only
        #expect(DateComponents(csvString: "   ") == nil)
        #expect(DateComponents(csvString: "\t\n") == nil)
    }

    @Test("Handle malformed dates")
    func malformedDates() {
        // Invalid month (13)
        let invalidMonth = DateComponents(csvString: "130124")
        #expect(invalidMonth?.month == 13) // Should parse but be invalid

        // Invalid day (32)
        let invalidDay = DateComponents(csvString: "013224")
        #expect(invalidDay?.day == 32) // Should parse but be invalid

        // Invalid month (00)
        let zeroMonth = DateComponents(csvString: "000124")
        #expect(zeroMonth?.month == 0) // Should parse but be invalid

        // Invalid day (00)
        let zeroDay = DateComponents(csvString: "010024")
        #expect(zeroDay?.day == 0) // Should parse but be invalid
    }

    @Test("Parse dates with whitespace")
    func datesWithWhitespace() {
        // Leading whitespace
        let leadingSpace = DateComponents(csvString: "  010124")
        #expect(leadingSpace?.year == 2024)
        #expect(leadingSpace?.month == 1)
        #expect(leadingSpace?.day == 1)

        // Trailing whitespace
        let trailingSpace = DateComponents(csvString: "010124  ")
        #expect(trailingSpace?.year == 2024)
        #expect(trailingSpace?.month == 1)
        #expect(trailingSpace?.day == 1)

        // Both leading and trailing
        let bothSpaces = DateComponents(csvString: "  010124  ")
        #expect(bothSpaces?.year == 2024)
        #expect(bothSpaces?.month == 1)
        #expect(bothSpaces?.day == 1)
    }

    @Test("TrimmedString handles empty strings")
    func trimmedStringEmpty() {
        let empty = TrimmedString(csvString: "")
        #expect(empty?.value == nil)

        let whitespaceOnly = TrimmedString(csvString: "   ")
        #expect(whitespaceOnly?.value == nil)

        let tabsNewlines = TrimmedString(csvString: "\t\n\r")
        #expect(tabsNewlines?.value == nil)
    }

    @Test("TrimmedString preserves non-empty content")
    func trimmedStringContent() {
        let normal = TrimmedString(csvString: "Hello World")
        #expect(normal?.value == "Hello World")

        let withSpaces = TrimmedString(csvString: "  Hello World  ")
        #expect(withSpaces?.value == "Hello World")

        let withTabs = TrimmedString(csvString: "\tHello\tWorld\t")
        #expect(withTabs?.value == "Hello\tWorld")

        let multiline = TrimmedString(csvString: "\nLine1\nLine2\n")
        #expect(multiline?.value == "Line1\nLine2")
    }

    @Test("OptionalTrimmedString behavior")
    func optionalTrimmedString() {
        let empty = OptionalTrimmedString(csvString: "")
        #expect(empty?.value == nil)

        let content = OptionalTrimmedString(csvString: "  Content  ")
        #expect(content?.value == "Content")

        let whitespaceOnly = OptionalTrimmedString(csvString: "\t \n")
        #expect(whitespaceOnly?.value == nil)
    }
}
