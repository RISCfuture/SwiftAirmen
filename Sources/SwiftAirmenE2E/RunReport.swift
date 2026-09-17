import Foundation

/// The machine-readable result of one end-to-end run.
struct RunReport: Codable, Sendable {
  /// Bumped when a field changes meaning, so a consumer can refuse a report it
  /// cannot read.
  static let currentSchemaVersion = 1

  let schemaVersion: Int
  /// The edition the run targeted, as `YYYY-MM`.
  let edition: String
  let finishedAt: Date
  let durationSeconds: Int
  let failed: Bool
  let failureReasons: [String]
  /// What ended the run before anything could be counted.
  let abortReason: String?
  let airmanCount: Int
  let certificateCount: Int
  /// Keyed by certificate kind, such as `mechanic`.
  let certificateCounts: [String: Int]
  let errorCount: Int
  /// Keyed by error kind, such as `unknownRating[AIRFR]`, most frequent first.
  let errorCounts: [String: Int]
  let errorSamples: [String]
  let drift: [DriftFinding]

  init(
    edition: Edition,
    durationSeconds: Int,
    abortReason: String? = nil,
    airmanCount: Int = 0,
    certificateCounts: [String: Int] = [:],
    errorCounts: [String: Int] = [:],
    errorSamples: [String] = [],
    drift: [DriftFinding] = []
  ) {
    schemaVersion = Self.currentSchemaVersion
    self.edition = edition.description
    finishedAt = Date()
    self.durationSeconds = durationSeconds
    self.abortReason = abortReason
    self.airmanCount = airmanCount
    self.certificateCounts = certificateCounts
    certificateCount = certificateCounts.values.reduce(0, +)
    self.errorCounts = errorCounts
    errorCount = errorCounts.values.reduce(0, +)
    self.errorSamples = errorSamples
    self.drift = drift

    var reasons: [String] = []
    if let abortReason { reasons.append(abortReason) }
    if errorCount > 0 {
      reasons.append("\(errorCount) parsing error(s) across \(errorCounts.count) kind(s)")
    }
    // A distribution the parser reads without complaint but finds nothing in is
    // a schema change that happens to be silent, not a clean run.
    if abortReason == nil, airmanCount == 0 {
      reasons.append("no airmen were parsed")
    }
    failureReasons = reasons
    failed = !reasons.isEmpty
  }

  /// Reads a report written by an earlier run, for use as a drift baseline.
  static func read(from url: URL) throws -> Self {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(Self.self, from: Data(contentsOf: url))
  }

  /// Writes the report as JSON, creating missing intermediate directories.
  func write(to url: URL) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    try encoder.encode(self).write(to: url)
  }

  func printSummary() {
    print("Edition \(edition): \(airmanCount) airmen, \(certificateCount) certificates")
    print("  Processing time: \(durationSeconds) seconds")
    if let abortReason { print("  Aborted: \(abortReason)") }

    if errorCounts.isEmpty {
      print("  No parsing errors.")
    } else {
      print("  \(errorCount) parsing error(s):")
      for (kind, count) in errorCounts.sorted(by: { $0.value > $1.value }) {
        print("    \(count)\t\(kind)")
      }
    }

    for finding in drift {
      print("  ⚠️ \(finding.metric): \(finding.was) → \(finding.now) (\(finding.reason))")
    }
  }
}

/// A count that moved far enough between two editions to be worth a look.
struct DriftFinding: Codable, Sendable {
  let metric: String
  let was: Int
  let now: Int
  let reason: String
}

/// Compares this run's counts against an earlier run's.
///
/// A count that quietly empties raises no parsing error at all, so the
/// comparison is the only thing that would ever mention it.
func driftFindings(
  from baseline: RunReport,
  airmanCount: Int,
  certificateCounts: [String: Int],
  percent: Int,
  minimum: Int
) -> [DriftFinding] {
  var findings: [DriftFinding] = []

  func compare(_ metric: String, was: Int, now: Int) {
    let delta = abs(now - was)
    guard delta >= minimum, delta * 100 >= was * percent else { return }
    let direction = now > was ? "rose" : "fell"
    findings.append(
      .init(metric: metric, was: was, now: now, reason: "\(direction) by \(delta)")
    )
  }

  compare("airmen", was: baseline.airmanCount, now: airmanCount)
  for kind in Set(baseline.certificateCounts.keys).union(certificateCounts.keys).sorted() {
    compare(
      "certificates.\(kind)",
      was: baseline.certificateCounts[kind] ?? 0,
      now: certificateCounts[kind] ?? 0
    )
  }

  return findings
}
