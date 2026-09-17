import ArgumentParser
import Foundation
@preconcurrency import Progress

@main
struct SwiftAirmenE2E: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Downloads and parses a full FAA airman database edition.",
    discussion: """
      Exits nonzero when the edition could not be downloaded or parsed, when any row failed to \
      parse, or when nothing was parsed at all. Count drift against a baseline is reported but \
      does not fail the run.
      """
  )

  @Option(
    name: .long,
    help: "The directory where data will be downloaded and unzipped.",
    completion: .directory,
    transform: { .init(filePath: $0) }
  )
  var workingDirectory: URL?

  @Option(
    name: .long,
    help: "The edition to check, as YYYY-MM. Defaults to the current month.",
    transform: Edition.init
  )
  var edition = Edition()

  @Option(name: .customLong("report"), help: "Path to write the JSON run report to.")
  var reportPath: String?

  @Option(
    name: .customLong("baseline"),
    help: "An earlier run's report, whose counts this run is compared against."
  )
  var baselinePath: String?

  @Option(name: .long, help: "Percentage a count must move by to count as drift.")
  var driftPercent = 10

  @Option(name: .long, help: "Records a count must move by to count as drift.")
  var driftMinimum = 25

  @Option(name: .long, help: "How many error samples to keep in the report.")
  var errorSamples = 25

  func validate() throws {
    guard driftPercent >= 0, driftMinimum >= 0 else {
      throw ValidationError("Drift thresholds cannot be negative.")
    }
    guard errorSamples >= 0 else {
      throw ValidationError("The error sample limit cannot be negative.")
    }
  }

  func run() async throws {
    setupProgress()

    let runner = Runner(
      edition: edition,
      workingDirectory: workingDirectory,
      errorSampleLimit: errorSamples
    )
    let report = try await withDrift(runner.run())

    report.printSummary()
    if let reportPath {
      try report.write(to: .init(filePath: reportPath))
    }
    if report.failed { throw ExitCode.failure }
  }

  // The baseline is applied after the fact so that a missing or unreadable one
  // cannot cost the run the counts it just spent ten minutes gathering.
  private func withDrift(_ report: RunReport) throws -> RunReport {
    guard let baselinePath else { return report }

    let baseline = try RunReport.read(from: .init(filePath: baselinePath))
    guard baseline.schemaVersion == RunReport.currentSchemaVersion else {
      print("Ignoring the baseline: it uses report schema \(baseline.schemaVersion).")
      return report
    }

    return RunReport(
      edition: edition,
      durationSeconds: report.durationSeconds,
      abortReason: report.abortReason,
      airmanCount: report.airmanCount,
      certificateCounts: report.certificateCounts,
      errorCounts: report.errorCounts,
      errorSamples: report.errorSamples,
      drift: driftFindings(
        from: baseline,
        airmanCount: report.airmanCount,
        certificateCounts: report.certificateCounts,
        percent: driftPercent,
        minimum: driftMinimum
      )
    )
  }

  private func setupProgress() {
    ProgressBar.defaultConfiguration = [
      ProgressPercent(decimalPlaces: 0),
      ProgressBarLine(),
      ProgressTimeEstimates()
    ]
  }
}
