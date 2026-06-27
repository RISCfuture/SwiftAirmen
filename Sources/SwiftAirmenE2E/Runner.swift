import Foundation
import SwiftAirmen

class Runner {
  func run() async throws {
    print("Downloading…")
    let folder = try await download()

    print("Processing…")
    let startTime = Date()
    let airmen = try await parse(folder: folder)
    let parseTime = Date().timeIntervalSince(startTime)

    print("Statistics")
    print("  Total airmen: \(airmen.count)")
    print("  Processing time: \(String(format: "%.2f", parseTime)) seconds")
    print("")

    testResult(airmen: airmen)
  }

  private func download() async throws -> URL {
    let downloader = try Downloader()
    let progressStream = downloader.progress
    let bar = DebouncedProgress()
    async let tracking: Void = bar.track(progressStream)
    let folder = try await downloader.download()
    await tracking
    return folder
  }

  private func parse(folder: URL) async throws -> [String: Airman] {
    let parser = Parser(directory: folder)
    let progress = AsyncProgress()
    let progressStream = progress.updates
    let bar = DebouncedProgress()
    async let tracking: Void = bar.track(progressStream)
    let (airmen, errors) = try await parser.parse(progress: progress)
    await tracking
    reportErrors(errors)
    return airmen
  }

  private func reportErrors(_ errors: [any Error]) {
    for error in errors.prefix(10) {
      print("⚠️ Parsing error: \(error)")
    }
    if errors.count > 10 {
      print("⚠️ … and \(errors.count - 10) more errors")
    }
  }

  func testResult(airmen: Parser.AirmanDictionary) {
    let mostCerts = airmen.values.max { $0.certificates.count < $1.certificates.count }!
    print("Airman with most certificates:")
    print(
      "\(mostCerts.debugDescription):\n\(mostCerts.certificates.map { "  \($0.description)" }.joined(separator: "\n"))"
    )
  }
}
