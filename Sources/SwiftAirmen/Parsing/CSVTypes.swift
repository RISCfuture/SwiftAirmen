public import Foundation
public import StreamingCSV

// Custom CSV decodable types
extension DateComponents: @retroactive CSVDecodable {
  private static let twoDigitYearPivot: UInt = 50

  /// Decodes a date written in the registry's `MMDDYY` or `MMDDYYYY` format.
  /// Month and day are carried through verbatim, so a component the registry
  /// records out of range stays out of range rather than rolling over.
  public init?(csvString: String) {
    let digits = csvString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard digits.count == 6 || digits.count == 8 else { return nil }

    let yearDigits = digits.dropFirst(4)
    guard let month = UInt(digits.prefix(2)),
      let day = UInt(digits.dropFirst(2).prefix(2)),
      let year = UInt(yearDigits)
    else { return nil }

    let fullYear = yearDigits.count == 2 ? Self.fullYear(fromTwoDigitYear: year) : year
    self.init(year: Int(fullYear), month: Int(month), day: Int(day))
  }

  /// The registry abbreviates years to two digits against a fixed 1950–2049
  /// window, rather than a window that moves with the current date.
  private static func fullYear(fromTwoDigitYear year: UInt) -> UInt {
    year >= twoDigitYearPivot ? 1900 + year : 2000 + year
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
