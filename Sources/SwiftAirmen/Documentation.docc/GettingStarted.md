# Getting Started

A tutorial on how to use SwiftAirmen.

## Usage

To download and unzip airmen records in CSV format, create an instance of
``Downloader``:

``` swift
import SwiftAirmen

let downloader = SwiftAirmen.Downloader()
let directoryURL = try await downloader.download()
```

``Downloader`` uses Swift's async/await for asynchronous operations. To observe
download progress, pass a `Subprogress` from your own `ProgressManager`:

``` swift
let progress = ProgressManager(totalCount: 1)
let directoryURL = try await downloader.download(
    progress: progress.subprogress(assigningCount: 1)
)
```

To parse airmen records, create an instance of ``Parser`` and give it the path
to your downloaded CSV records:

``` swift
let parser = SwiftAirmen.Parser(directory: directoryURL)
let (airmen, errors) = try await parser.parse()
// inspect `errors` for any non-fatal parsing errors
```

``Parser/parse(files:progress:)`` executes asynchronously using Swift's
async/await and returns a ``Parser/AirmanDictionary`` together with any
non-fatal errors. Each offending row is skipped but parsing is not aborted, and
the errors are returned alongside the records.

It accepts a `Subprogress` as well. `ProgressManager` is `Observable`, so you can
observe it rather than poll it:

``` swift
let progress = ProgressManager(totalCount: 1)
let monitor = Task {
    for await percent in Observations.untilFinished({
        progress.isFinished ? .finish : .next(Int(progress.fractionCompleted * 100))
    }) {
        print("\(percent)%")
    }
}
let (airmen, errors) = try await parser.parse(
    progress: progress.subprogress(assigningCount: 1)
)
await monitor.value
```

An ``Airman`` record contains information about the airman and their
certificates:

``` swift
let airman = airmen["A4760216"]
print(airman.firstName)
for cert in airman.certificates {
    guard case let .pilot(level, ratings, centerlineThrust) = cert else { continue }
    if level == .airlineTransport {
        // your code continues
    }
}
```

To simplify debugging, the ``Airman`` class implements
``Airman/debugDescription``, and the ``Certificate`` enum (and its various
associated classes) implements ``Certificate/description``. These can be used
to print English descriptions of an Airman or their certificates/ratings.

Parsing is an expensive operation. See the ``Parser`` class for methods that
will allow you to parse a subset of the airmen certification data.
