# Change Log

## [3.1.0] - 2026-07-06

### Added

- Linux support. The archive downloader now uses ZIPFoundation in place of the
  Apple-only `Zip` dependency, `URLSession` is guarded behind
  `FoundationNetworking`, and a `String(localized:)` shim covers error strings.
  On Linux the download falls back to a buffered `URLSession.data(for:)` (Apple
  keeps the incremental streaming path).

## [3.0.0] - 2026-06-26

### Changed (breaking)

- `Parser.parse` no longer takes an `errorCallback`. It now returns the parsed
  records together with the non-fatal errors it encountered:
  `let (airmen, errors) = try await parser.parse()`. The `progress:` argument is
  now optional and defaults to `nil`.
- `Downloader` reports progress through a new `progress`
  (`AsyncStream<Progress>`) instead of an `init` progress callback. Iterate it
  to observe download progress.
- `AsyncProgress` reports updates through a new `updates`
  (`AsyncStream<Progress>`) instead of a `callback` closure; its initializer is
  now `AsyncProgress()`.
- `Progress` is now an immutable `Sendable` struct rather than an `actor`, so
  reading `completed`, `total`, `percentDone`, etc. no longer requires `await`.

### Changed

- Migrated from csv.swift to StreamingCSV library for CSV parsing
- Implemented parallel processing at two levels: concurrent file processing and
  parallel chunk processing within each file
- Progress tracking now based on total bytes across all files instead of
  per-file tracking
- Significant performance improvements for parsing large airman databases

### Removed

- Removed the `Parser.ProgressCallback`, `Parser.ErrorCallback`, and
  `Downloader.ProgressCallback` typealiases.

### Fixed

- Fixed certificate deduplication issue in `mergedWith` function
- Improved memory handling for large CSV files

### Internal

- Adopted the Approachable Concurrency upcoming features
  (`NonisolatedNonsendingByDefault`, `InferIsolatedConformances`)
- Dropped unnecessary `@unchecked Sendable` conformances from the internal row
  parsers
- Removed a redundant continuation wrapping the synchronous unzip step
- Replaced NSLock-backed error collectors with returned error arrays / an actor

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
