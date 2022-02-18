import Foundation
import SwiftAirmen
import Dispatch

let queue = DispatchQueue(label: "codes.tim.SwiftAirmen.main", qos: .default, attributes: .concurrent)

let group = DispatchGroup()
group.enter()

let progress = Progress(totalUnitCount: 1)

queue.async {
    let parser = SwiftAirmen.Parser(directory: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").appendingPathComponent("CS022022"))
    
    let subprogress = try! parser.parse(callback: { airmen in
        let mostCerts = airmen.values.max(by: { $0.certificates.count < $1.certificates.count })!
        print("\(mostCerts.debugDescription):\n\(mostCerts.certificates.map { "  \($0.description)" }.joined(separator: "\n"))")
        group.leave()
    }, errorCallback: { error in print("ERROR: \(error)") })
    
    progress.addChild(subprogress, withPendingUnitCount: 1)
}

queue.async {
    while !progress.isFinished {
        let percent = (progress.fractionCompleted*100).rounded()
        print("\(Int(percent))%")
        sleep(5)
    }
}

group.wait()
