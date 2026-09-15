# Change Log

## [Unreleased]

### Changed (breaking)

- Progress reporting now uses Foundation's `ProgressManager` (SF-0023) instead of
  SwiftAirmen's own `Progress` struct. The data flow is inverted: rather than the
  callee publishing snapshots *up* through an `AsyncStream`, the caller passes a
  `Subprogress` *down*.
  - `Parser.parse(files:progress:)` takes `progress: consuming Subprogress? = nil`
    in place of `AsyncProgress?`.
  - `Downloader.progress` (the `AsyncStream<Progress>` property) is gone;
    `download(progress:)` accepts a `consuming Subprogress?` instead.
  - `Progress` and `AsyncProgress` are removed. Read `completedCount`,
    `fractionCompleted`, and `isFinished` from your own `ProgressManager`, which
    is `Observable` — so progress can be followed with
    `Observations.untilFinished` rather than by iterating a stream.
- Raised the minimum deployment targets to macOS 27, iOS 27, tvOS 27, watchOS 27,
  and visionOS 27, and the package tools-version to 6.4. `ProgressManager` has no
  lower availability annotation, and `MacOSVersion.v27` requires
  `_PackageDescription 6.4`.

### Added

- Parsing reports `totalByteCount`/`completedByteCount` and
  `totalFileCount`/`completedFileCount` per CSV file, so a progress UI can show
  byte and file counts alongside the fraction. These are recorded on leaf
  managers only, since `summary(of:)` sums the whole subtree.

### Changed

- `Downloader.dataURL()` builds the archive URL with `URL.Template` rather than
  two `replacingOccurrences(of:with:)` calls on a format string.

### Fixed

- Download progress is reported about once per megabyte received instead of
  once per byte, so observing a download no longer costs an update for every
  byte of a multi-hundred-megabyte archive. A final report is still made on
  completion.
- `folderLocation()` returned a URL built from the *zipfile* name in its
  pre-macOS 13 fallback branch, disagreeing with the primary branch. The floor is
  now above that check, so the branch and the bug are gone.

## [3.2.0] - 2026-09-14

### Changed

- Swift 6.3 is now the minimum toolchain. StreamingCSV 2.1.0 carries a Swift
  6.3 manifest, so Swift 6.1 and 6.2 can no longer resolve this package.
- Raised dependency floors to StreamingCSV 2.1.0, swift-argument-parser 1.8.2,
  ZIPFoundation 0.9.20, and swift-docc-plugin 1.5.0.

### Internal

- Enabled the ExistentialAny, InternalImportsByDefault, MemberImportVisibility,
  and ImmutableWeakCaptures upcoming features on every target, alongside the
  Approachable Concurrency ones. The package still declares both the v5 and v6
  language modes, so no consumer source change is required.
- Tests name themselves with Swift 6.2 raw identifiers instead of `@Test` and
  `@Suite` display-name strings.

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
