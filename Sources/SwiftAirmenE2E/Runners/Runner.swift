import Foundation
import SwiftAirmen

class Runner {
    func testResult(airmen: Parser.AirmanDictionary) {
        let mostCerts = airmen.values.max(by: { $0.certificates.count < $1.certificates.count })!
        print("\(mostCerts.debugDescription):\n\(mostCerts.certificates.map { "  \($0.description)" }.joined(separator: "\n"))")
    }
}
