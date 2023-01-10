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

``Downloader`` supports both traditional callback-style syntax as well as
`async` syntax. See the class documentation for more examples.

To parse airmen records, create an instance of ``Parser`` and give it the path
to your downloaded CSV records:

``` swift
let parser = SwiftAirmen.Parser(directory: directoryURL)
let airmen = try await parser.parse(errorCallback: { error in
  // your error handler here
})
```

``Parser/parse(files:progress:errorCallback:)`` executes asynchronously and
returns a ``Parser/AirmanDictionary``. Any parsing errors that occur are given
to you via `errorCallback`. The row is skipped but parsing is not aborted.

``Parser`` supports traditional callback-style syntax, Combine publisher syntax,
and `async` syntax. See the class documentation for more examples.

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
