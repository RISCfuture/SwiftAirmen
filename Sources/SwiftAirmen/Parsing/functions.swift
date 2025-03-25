import Foundation

func parseDate(_ string: String?) throws -> DateComponents? {
    guard let string else { return nil }
    guard !string.isEmpty else { return nil }

    var start = string.startIndex
    var end = string.index(start, offsetBy: 1)
    guard let month = UInt(string[start...end]) else { throw Errors.invalidDate(string) }

    start = string.index(after: end)
    end = string.index(start, offsetBy: 1)
    guard let day = UInt(string[start...end]) else { throw Errors.invalidDate(string) }

    let year: UInt
    if string.count == 6 {
        start = string.index(after: end)
        end = string.index(start, offsetBy: 1)
        guard let year2 = UInt(string[start...end]) else { throw Errors.invalidDate(string) }
        guard year2 >= 0 && year2 <= 99 else { throw Errors.invalidDate(string) }

        if year2 >= 50 { year = 1900 + year2 }
        else { year = 2000 + year2 }
    } else {
        start = string.index(after: end)
        end = string.index(start, offsetBy: 3)
        guard let year4 = UInt(string[start...end]) else { throw Errors.invalidDate(string) }

        year = year4
    }

    return .init(year: Int(year), month: Int(month), day: Int(day))
}

func trim(_ str: String?) -> String? {
    guard let str else { return nil }
    let trimmed = str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}
