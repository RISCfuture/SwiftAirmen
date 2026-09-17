import ArgumentParser
import Foundation

/// One monthly edition of the airman database.
///
/// The FAA names the archive `CSMMYYYY.zip` and publishes each edition on the
/// first of its month, keeping only the current one and the one before it.
struct Edition: Sendable, Equatable, CustomStringConvertible {
  private static let calendar = Calendar(identifier: .gregorian)

  let year: Int
  let month: Int

  /// A date inside this edition's month, which ``Downloader`` reduces back to
  /// the month and year that name the archive.
  var date: Date {
    let components = DateComponents(year: year, month: month, day: 15, hour: 12)
    guard let date = Self.calendar.date(from: components) else {
      preconditionFailure("\(self) is not a representable date.")
    }
    return date
  }

  // Printf rather than a `FormatStyle`: this string keys report files and
  // artifacts, so it has to stay byte-stable across locales.
  var description: String { "\(year)-\(String(format: "%02d", month))" }

  /// The edition for the month containing `date`.
  init(containing date: Date = Date()) {
    let components = Self.calendar.dateComponents([.year, .month], from: date)
    guard let year = components.year, let month = components.month else {
      preconditionFailure("Couldn’t get month/year from date \(date).")
    }
    self.year = year
    self.month = month
  }

  /// Parses an edition written as `YYYY-MM`.
  init(_ string: String) throws {
    let parts = string.split(separator: "-", omittingEmptySubsequences: false)
    guard parts.count == 2,
      parts[0].count == 4,
      parts[1].count == 2,
      let year = Int(parts[0]),
      let month = Int(parts[1]),
      (1...12).contains(month)
    else {
      throw ValidationError("‘\(string)’ is not an edition. Use YYYY-MM, such as 2026-09.")
    }
    self.year = year
    self.month = month
  }
}
