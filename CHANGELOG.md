# Change Log

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
