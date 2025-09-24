import Foundation
import StreamingCSV

// Custom CSV decodable types
extension DateComponents: @retroactive CSVDecodable {
  public init?(csvString: String) {
    let csvValue = csvString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !csvValue.isEmpty else { return nil }

    // Date format is MMDDYY or MMDDYYYY
    guard csvValue.count == 6 || csvValue.count == 8 else { return nil }

    // Safely extract month (MM)
    guard csvValue.count >= 2 else { return nil }
    let monthEnd = csvValue.index(csvValue.startIndex, offsetBy: 2)
    guard let month = UInt(csvValue[csvValue.startIndex..<monthEnd]) else { return nil }

    // Safely extract day (DD)
    guard csvValue.count >= 4 else { return nil }
    let dayStart = monthEnd
    let dayEnd = csvValue.index(dayStart, offsetBy: 2)
    guard let day = UInt(csvValue[dayStart..<dayEnd]) else { return nil }

    // Safely extract year (YY or YYYY)
    let yearStart = dayEnd
    let year: UInt
    if csvValue.count == 6 {
      // Two-digit year
      let yearEnd = csvValue.index(yearStart, offsetBy: 2)
      guard let year2 = UInt(csvValue[yearStart..<yearEnd]) else { return nil }

      if year2 >= 50 { year = 1900 + year2 } else { year = 2000 + year2 }
    } else if csvValue.count == 8 {
      // Four-digit year
      let yearEnd = csvValue.index(yearStart, offsetBy: 4)
      guard let year4 = UInt(csvValue[yearStart..<yearEnd]) else { return nil }
      year = year4
    } else {
      return nil
    }

    self = DateComponents(year: Int(year), month: Int(month), day: Int(day))
  }
}

// Helper for trimming and converting empty strings to nil
struct TrimmedString: CSVDecodable {
  let value: String?

  init?(csvString: String) {
    let trimmed = csvString.trimmingCharacters(in: .whitespacesAndNewlines)
    self.value = trimmed.isEmpty ? nil : trimmed
  }
}

// Wrapper for optional trimmed strings
struct OptionalTrimmedString: CSVDecodable {
  let value: String?

  init?(csvString: String) {
    let trimmed = csvString.trimmingCharacters(in: .whitespacesAndNewlines)
    self.value = trimmed.isEmpty ? nil : trimmed
  }
}
