//  `String(localized:)` comes from FoundationInternationalization on Apple platforms but
//  is unavailable on Linux. This package uses its default ("en") localization text as the
//  lookup key, so on Linux we resolve each key to itself. Excluded on Apple, where the
//  real Foundation API is used.

#if !canImport(Darwin)
  import Foundation

  extension String {
    init(
      localized key: String,
      table _: String? = nil,
      bundle _: Bundle? = nil,
      locale _: Locale? = nil,
      comment _: StaticString? = nil
    ) {
      self = key
    }
  }
#endif
