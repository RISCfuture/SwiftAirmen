import Foundation

actor AirmanDatabase {
  private var airmen = [Airman]()

  @discardableResult
  func append(airmen: [Airman]) -> Self {
    self.airmen.append(contentsOf: airmen)
    return self
  }

  @discardableResult
  func append(airman: Airman) -> Self {
    self.airmen.append(airman)
    return self
  }

  func merged() -> [String: Airman] {
    var airmenDict = [String: Airman]()
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
