import Foundation
import Dispatch

class AirmanDatabase {
    private var airmen = Array<Airman>()
    private let airmenSemaphore = DispatchSemaphore(value: 1)
    private let queue = DispatchQueue(label: "codes.tim.SwiftAirmen.AirmanDatabase", qos: .background, attributes: .concurrent)
    
    @discardableResult
    func append(airmen: Array<Airman>) -> Self {
        queue.async {
            self.airmenSemaphore.wait()
            defer { self.airmenSemaphore.signal() }
            
            self.airmen.append(contentsOf: airmen)
        }
        return self
    }
    
    @discardableResult
    func append(airman: Airman) -> Self {
        queue.async {
            self.airmenSemaphore.wait()
            defer { self.airmenSemaphore.signal() }
            
            self.airmen.append(airman)
        }
        return self
    }
    
    func merged(callback: @escaping (Dictionary<String, Airman>) -> Void) {
        queue.async {
            let dict = self.merged()
            callback(dict)
        }
    }
    
    func merged() -> Dictionary<String, Airman> {
        self.airmenSemaphore.wait()
        defer { self.airmenSemaphore.signal() }
        
        var airmenDict = Dictionary<String, Airman>()
        for airman in self.airmen {
            if let existingAirman = airmenDict[airman.id] {
                airmenDict[airman.id] = existingAirman.mergedWith(airman)
            } else {
                airmenDict[airman.id] = airman
            }
        }
        
        return airmenDict
    }
}
