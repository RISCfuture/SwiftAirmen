import Foundation
import SwiftAirmen

/// Downloads one edition of the airman database, parses it, and reports what it found.
struct Runner {
  let edition: Edition
  let workingDirectory: URL?
  let errorSampleLimit: Int

  /// Runs the check. A download or parse that throws ends the run but still
  /// produces a report, which is how the failure gets recorded.
  func run() async -> RunReport {
    let startedAt = Date()
    func elapsed() -> Int { Int(Date().timeIntervalSince(startedAt).rounded()) }

    do {
      print("Downloading \(edition)…")
      let folder = try await download()

      print("Processing…")
      let (airmen, errors) = try await parse(folder: folder)

      describeMostCertificated(among: airmen)
      return RunReport(
        edition: edition,
        durationSeconds: elapsed(),
        airmanCount: airmen.count,
        certificateCounts: certificateCounts(in: airmen),
        errorCounts: errorCounts(in: errors),
        errorSamples: errorSamples(from: errors)
      )
    } catch {
      return RunReport(
        edition: edition,
        durationSeconds: elapsed(),
        abortReason: error.localizedDescription
      )
    }
  }

  private func download() async throws -> URL {
    // `Downloader` writes into this directory rather than creating it, and a
    // missing one surfaces as the archive itself being absent.
    if let workingDirectory {
      try FileManager.default.createDirectory(
        at: workingDirectory,
        withIntermediateDirectories: true
      )
    }
    let downloader = try Downloader(date: edition.date, workingDirectory: workingDirectory)
    let progress = ProgressManager(totalCount: 1)
    let bar = DebouncedProgress()
    async let tracking: Void = bar.track(progress)
    let folder = try await downloader.download(
      progress: progress.subprogress(assigningCount: 1)
    )
    await tracking
    return folder
  }

  private func parse(folder: URL) async throws -> (Parser.AirmanDictionary, [any Error]) {
    let parser = Parser(directory: folder)
    let progress = ProgressManager(totalCount: 1)
    let bar = DebouncedProgress()
    async let tracking: Void = bar.track(progress)
    let result = try await parser.parse(progress: progress.subprogress(assigningCount: 1))
    await tracking
    return result
  }

  private func certificateCounts(in airmen: Parser.AirmanDictionary) -> [String: Int] {
    var counts: [String: Int] = [:]
    for airman in airmen.values {
      for certificate in airman.certificates {
        counts[certificate.kind, default: 0] += 1
      }
    }
    return counts
  }

  private func errorCounts(in errors: [any Error]) -> [String: Int] {
    var counts: [String: Int] = [:]
    for error in errors {
      counts[error.reportKind, default: 0] += 1
    }
    return counts
  }

  // One sample per kind, so a distribution that breaks in several ways shows
  // each of them rather than the first one thousands of times.
  private func errorSamples(from errors: [any Error]) -> [String] {
    var seen = Set<String>()
    var samples: [String] = []
    for error in errors where seen.insert(error.reportKind).inserted {
      samples.append("[\(error.reportKind)] \(error.localizedDescription)")
      if samples.count == errorSampleLimit { break }
    }
    return samples
  }

  private func describeMostCertificated(among airmen: Parser.AirmanDictionary) {
    guard let airman = airmen.values.max(by: { $0.certificates.count < $1.certificates.count })
    else { return }
    print("Airman with most certificates:")
    print(airman.debugDescription)
    for certificate in airman.certificates { print("  \(certificate.description)") }
  }
}
