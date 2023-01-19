# SwiftAirmen: FAA Airman Database parser

SwiftAirmen parses the
[FAA Airmen Certification Database](https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download/)
into native Swift structs that are tightly defined with no data weirdness. You
must download a copy of the airmen database in CSV format from that website to
use with this library.

## Requirements

This library was built for use with Swift 5.5 or newer on any platform or
architecture.

## Installation

Use Swift Package Manager to include SwiftAirmen in your project:

``` swift
let package = Package(
    // [...]
    dependencies: [
        .package(url: "https://github.com/RISCfuture/SwiftAirmen", branch: "main")
    ],
    // [...]
)
```

Be sure to include SwiftAirmen as a dependency in your `.target` entry.

## Usage

To download and unzip airmen records in CSV format, create an instance of
`Downloader`:

``` swift
import SwiftAirmen

let downloader = SwiftAirmen.Downloader()
let directoryURL = try await downloader.download()
```

`Downloader` supports both traditional callback-style syntax as well as
`async` syntax. See the class documentation for more examples.

To parse airmen records, create an instance of `Parser` and give it the path
to your downloaded CSV records:

``` swift
let parser = SwiftAirmen.Parser(directory: directoryURL)
let airmen = try await parser.parse(errorCallback: { error in
  // your error handler here
})
```

`parse` executes asynchronously and returns a dictionary mapping airman unique
IDs to the `Airman` record for that airman. Any parsing errors that occur are
given to you via `errorCallback`. The row is skipped but parsing is not aborted.

`Parser` supports traditional callback-style syntax, Combine publisher syntax,
and `async` syntax. See the class documentation for more examples.

An `Airman` record contains information about the airman and their
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

To simplify debugging, the `Airman` class implements `debugDescription`, and the
`Certificate` enum (and its various associated classes) implements
`description`. These can be used to print English descriptions of an Airman or
their certificates/ratings.

Parsing is an expensive operation. See the `Parser` class for methods that will
allow you to parse a subset of the airmen certification data.

## Documentation

Online API and tutorial documentation is available at
https://riscfuture.github.io/SwiftAirmen/documentation/swiftairmen/

DocC documentation is available, including tutorials and API documentation. For
Xcode documentation, you can run

``` sh
swift package generate-documentation --target SwiftAirmen
```

to generate a docarchive at
`.build/plugins/Swift-DocC/outputs/SwiftAirmen.doccarchive`. You can open this
docarchive file in Xcode for browseable API documentation. Or, within Xcode,
open the SwiftAirmen package in Xcode and choose **Build Documentation** from the
**Product** menu.
