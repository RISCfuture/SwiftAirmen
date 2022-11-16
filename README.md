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
        .package(url: "https://github.com/RISCfuture/SwiftAirmen", branch: "master")
    ],
    // [...]
)
```

Be sure to include SwiftAirmen as a dependency in your `.target` entry.

## Usage

To parse airmen records, create an instance of `Parser` and give it the path to
your downloaded CSV records:

``` swift
import SwiftAirmen

let parser = SwiftAirmen.Parser(directory: yourDirectoryURL)
try parser.parse(callback: { airmen in
    // your code here
}, errorCallback: { error in
    // your error handler here
})
```

`parse` executes asynchronously and calls your callback when parsing is
complete. The `airmen` block parameter is a dictionary mapping airmen IDs (such
as `A4760216`) to `Airman` records.

An `Airman` record contains information about the airman and their certificates:

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

If you wish to track the progress of the parsing operation, `parse`
returns a `Progress` instance that you can use. Any parsing errors are
non-interruptive and will be given to you in the error callback, which is
invoked once per parse error. The final `airmen` parameter passed to the
callback includes those records that were parsed without error.

Parsing is an expensive operation. See the `Parser` class for methods that will
allow you to parse a subset of the airmen certification data.

## Documentation

DocC documentation is available, including tutorials and API documentation. For
Xcode documentation, you can run

``` sh
swift package generate-documentation --target SwiftAirmen
```

to generate a docarchive at
`.build/plugins/Swift-DocC/outputs/SwiftAirmen.doccarchive`. You can open this
docarchive file in Xcode for browseable API documentation. Or, within Xcode,
open the SwiftNASR package in Xcode and choose **Build Documentation** from the
**Product** menu.
