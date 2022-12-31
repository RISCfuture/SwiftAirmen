# ``SwiftAirmen``

SwiftAirmen parses the FAA Airman Database.

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

## Topics

### Parsing

- <doc:GettingStarted>
- ``Parser``

### Airmen

- ``Airman``
- ``Certificate``
- ``Medical``

### Supporting Types

- ``Errors``
