# Getting Started

A tutorial on how to use SwiftAirmen.

## Usage

To parse airmen records, create an instance of ``Parser`` and give it the path
to your downloaded CSV records:

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
as `A4760216`) to ``Airman`` records.

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

If you wish to track the progress of the parsing operation,
``Parser/parse(callback:errorCallback:)`` returns a `Progress` instance that you
can use. Any parsing errors are non-interruptive and will be given to you in the
error callback, which is invoked once per parse error. The final `airmen`
parameter passed to the callback includes those records that were parsed without
error.

Parsing is an expensive operation. See the ``Parser`` class for methods that will
allow you to parse a subset of the airmen certification data.
