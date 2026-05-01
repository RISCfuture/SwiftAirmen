# Change Log

## [2.1.0] - 2026-05-01

### Changed

- CSV parsing now backed by [StreamingCSV](https://github.com/RISCfuture/StreamingCSV) for improved performance
- Migrated localized strings to Swift string catalogs

### Internal

- Updated to Swift 6 and Swift 6.2; CI matrix standardized to Swift 6.0–6.2 on macOS 14–15
- Added swift-format and SwiftLint
- Modernized Optional syntax
- Updated GitHub Actions and Package dependencies
- Added documentation root redirect

## [3.0.0]

Updated minimum Swift version to 6.1.

### Changed

- Migrated from csv.swift to StreamingCSV library for CSV parsing
- Implemented parallel processing at two levels: concurrent file processing and 
  parallel chunk processing within each file
- Progress tracking now based on total bytes across all files instead of
  per-file tracking
- Significant performance improvements for parsing large airman databases

### Fixed

- Fixed certificate deduplication issue in `mergedWith` function
- Improved memory handling for large CSV files

## [2.0.0] - 2024-04-04

Significant rewrite of the primary classes.

### Added

- Added `Downloader` class
- Added async/await, Combine, and callback method variations to `Parser`
- Added DocC documentation
- Added localization to errors

### Changed

- More sophisticated progress tracking
- Locked down version requirements

## [1.0.0] - 2022-03-04

Initial release.
