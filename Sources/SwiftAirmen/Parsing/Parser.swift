public import Foundation
import StreamingCSV

/// Parses an airman certification database into memory. The database must be
/// downloaded in CSV format and stored, unarchived, in a directory somewhere
/// accessible. The names of the CSV files must not be changed.
///
/// The parser uses parallel processing at two levels:
///
/// - Multiple CSV files are processed concurrently
/// - Each individual CSV file is parsed using parallel chunk processing
///
/// This provides significant performance improvements when parsing the full
/// airman database.
///
/// Call the ``parse(files:progress:)`` method to parse the airman database. The
/// method uses Swift's async/await concurrency and returns an
/// ``AirmanDictionary`` along with any non-fatal errors encountered. To observe
/// progress, hand it a `Subprogress` from your own `ProgressManager`.
///
/// You can use ``Downloader`` to download the CSV file automatically. See
/// <doc:GettingStarted> for an example.
public final class Parser: Sendable {
  /**
   Return value for all `parse` methods. A dictionary mapping an airman's
   unique ID (such as `A4760216`) to the ``Airman`` record, which contains all
   data loaded for that airman.
   */
  public typealias AirmanDictionary = [String: Airman]

  static let rowParser: [File: any RowParser.Type] = [
    .pilotBasic: BasicRowParser.self,
    .nonpilotBasic: BasicRowParser.self,
    .pilotCert: PilotCertRowParser.self,
    .nonPilotCert: NonPilotCertRowParser.self
  ]

  /// The directory that the parser will look for CSV files in.
  public let directory: URL

  /**
   Creates a new instance.

   - Parameter directory: The directory containing the CSV files.
   */
  public init(directory: URL) {
    self.directory = directory
  }

  func url(for file: File) -> URL {
    directory.appendingPathComponent(file.rawValue)
  }

  // MARK: - Private Methods

  /// The size of a file in bytes, or zero when it is missing or unreadable.
  private func fileSize(of url: URL) -> Int {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
      return 0
    }
    return attributes[.size] as? Int ?? 0
  }

  /**
   Parses all airmen records in one or more files using parallel processing.

   Files are processed concurrently, and each file uses internal parallel chunk
   processing for maximum performance. Progress is tracked as a unified total
   across all files based on bytes processed.

   Errors do not stop parsing; the offending row is skipped and the error is
   returned alongside the parsed records.

   - Parameter files: The files to parse. This array should be unique,
   otherwise parsing will be unnecessarily slower.
   - Parameter progress: Pass a `Subprogress` from your own `ProgressManager` if
   you wish to track parsing progress. Each file is weighted by its byte size, so
   the reported fraction tracks the work remaining rather than the number of
   files left.
   - Returns: A dictionary mapping airman identifiers to their records, and the
   non-fatal errors encountered while parsing (an empty array if none).
   */
  public func parse(
    files: [File] = File.allCases,
    progress: consuming Subprogress? = nil
  ) async throws -> (airmen: AirmanDictionary, errors: [any Error]) {

    let db = AirmanDatabase()
    let errorLog = ErrorLog()

    let sizes = files.map { fileSize(of: url(for: $0)) }
    let totalBytes = sizes.reduce(0, +)

    // Files are parsed concurrently, so each gets its own `ProgressManager`
    // wired in by reporter — a `Subprogress` is noncopyable and could not be
    // captured by the task group's escaping closures.
    // Byte and file counts are recorded on the leaves only: `summary(of:)` sums
    // the whole subtree, so a value on the parent as well would double-count.
    let parent = progress?.start(totalCount: totalBytes > 0 ? totalBytes : nil)
    func leaf(ofSize size: Int) -> ProgressManager? {
      let child = parent?.child(assigningCount: size, totalCount: size > 0 ? size : nil)
      child?.totalByteCount = UInt64(size)
      child?.totalFileCount = 1
      return child
    }

    let fileProgress = zip(files, sizes).map { file, size in
      (file: file, progress: leaf(ofSize: size))
    }

    await withTaskGroup(of: Void.self) { group in
      for (file, progress) in fileProgress {
        group.addTask { [self] in
          await parseFile(file, into: db, progress: progress, errorLog: errorLog)
        }
      }
    }

    return (airmen: await db.merged(), errors: await errorLog.collect())
  }

  // Parses a single CSV file and adds airmen to the database
  private func parseFile(
    _ file: File,
    into database: AirmanDatabase,
    progress: ProgressManager?,
    errorLog: ErrorLog
  ) async {
    let url = url(for: file)
    let size = fileSize(of: url)

    // Whether the file parses or not, its share of the total is settled, so a
    // missing or malformed file cannot leave the overall fraction short of 1.
    defer {
      progress?.finish()
      progress?.completedByteCount = UInt64(size)
      progress?.completedFileCount = 1
    }

    guard FileManager.default.fileExists(atPath: url.path) else {
      await errorLog.record(Errors.fileNotFound(url: url))
      return
    }

    do {
      let rowParserType = Self.rowParser[file]!
      let rowParser = rowParserType.init()

      let reader = ParallelCSVReader(url: url, delimiter: ",", quote: "\"", escape: "\"")
      let tracker = ProgressTracker(fileSize: size, progress: progress)

      try await reader.processRows { [self] fields in
        await processRow(
          fields: fields,
          with: rowParser,
          into: database,
          tracker: tracker,
          errorLog: errorLog
        )
      }
    } catch {
      await errorLog.record(error)
    }
  }

  // Processes a single CSV row
  private func processRow(
    fields: [String],
    with rowParser: any RowParser,
    into database: AirmanDatabase,
    tracker: ProgressTracker,
    errorLog: ErrorLog
  ) async {
    await tracker.incrementRow()

    do {
      if let airman = try rowParser.parse(fields: fields) {
        await database.append(airman: airman)
      }
    } catch {
      await errorLog.record(error)
    }
  }

  /// A CSV file within an airman database distribution to parse.
  public enum File: String, CaseIterable, Sendable {

    /// Parse the `PILOT_BASIC.csv` file.
    case pilotBasic = "PILOT_BASIC.csv"

    /// Parse the `NONPILOT_BASIC.csv` file.
    case nonpilotBasic = "NONPILOT_BASIC.csv"

    /// Parse the `PILOT_CERT.csv` file.
    case pilotCert = "PILOT_CERT.csv"

    /// Parse the `NONPILOT_CERT.csv` file.
    case nonPilotCert = "NONPILOT_CERT.csv"
  }
}

// MARK: - ProgressTracker

// Estimates a file's byte progress from the number of rows read, since
// `ParallelCSVReader` reports rows rather than file offsets. Rows arrive from
// concurrent chunk workers, so the running count is actor-isolated.
//
// The estimate only ever moves progress forward and is clamped to the file's
// size; `Parser.parseFile` settles the remainder when the file is done.
private actor ProgressTracker {
  private static let updateInterval = 100

  // Typical row width across the FAA distribution.
  private static let estimatedBytesPerRow = 150

  private let fileSize: Int
  private let progress: ProgressManager?
  private var rowCount = 0
  private var bytesReported = 0

  init(fileSize: Int, progress: ProgressManager?) {
    self.fileSize = fileSize
    self.progress = progress
  }

  func incrementRow() {
    rowCount += 1
    guard let progress, rowCount.isMultiple(of: Self.updateInterval) else { return }

    let batch = Self.estimatedBytesPerRow * Self.updateInterval
    let remaining = fileSize - bytesReported
    guard remaining > 0 else { return }

    bytesReported += min(batch, remaining)
    progress.setCompletedCount(bytesReported)
    progress.completedByteCount = UInt64(bytesReported)
  }
}

// MARK: - ErrorLog

// Collects non-fatal parsing errors from concurrent file-parsing tasks.
private actor ErrorLog {
  private var errors: [any Error] = []

  func record(_ error: sending any Error) {
    errors.append(error)
  }

  func collect() -> sending [any Error] {
    let collected = errors
    errors = []
    return collected
  }
}
