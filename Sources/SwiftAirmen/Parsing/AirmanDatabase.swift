import Foundation
import Dispatch

class AirmanDatabase {
    private var airmen = Array<Airman>()
    private let airmenSemaphore = DispatchSemaphore(value: 1)
    private let queue = DispatchQueue(label: "codes.tim.SwiftAirmen.AirmanDatabase", qos: .background, attributes: .concurrent)
    
    func append(airmen: Array<Airman>) {
        queue.async {
            self.airmenSemaphore.wait()
            defer { self.airmenSemaphore.signal() }
            
            self.airmen.append(contentsOf: airmen)
        }
    }
    
    @discardableResult func merged(callback: @escaping (Dictionary<String, Airman>) -> Void) -> Progress {
        let progress = Progress()
        
        queue.async {
            self.airmenSemaphore.wait()
            defer { self.airmenSemaphore.signal() }
            
            progress.totalUnitCount = Int64(self.airmen.count)
            
            var airmenDict = Dictionary<String, Airman>()
            for airman in self.airmen {
                if let existingAirman = airmenDict[airman.id] {
                    airmenDict[airman.id] = existingAirman.mergedWith(airman)
                } else {
                    airmenDict[airman.id] = airman
                }
                progress.completedUnitCount += 1
            }
            
            callback(airmenDict)
        }
        
        return progress
    }
}
