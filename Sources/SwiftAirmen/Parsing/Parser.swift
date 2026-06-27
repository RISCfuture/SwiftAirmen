import Foundation
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
/// ``AirmanDictionary`` along with any non-fatal errors encountered.
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

  /// Calculates the total file size across all specified files for progress tracking
  private func calculateTotalFileSize(for files: [File]) throws -> Int64 {
    var totalBytes: Int64 = 0
    for file in files {
      let url = self.url(for: file)
      if FileManager.default.fileExists(atPath: url.path) {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        totalBytes += Int64(fileAttributes[.size] as? Int ?? 0)
      }
    }
    return totalBytes
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
   - Parameter progress: Create an instance of ``AsyncProgress`` and pass it
   here if you wish to track parsing progress. Progress is reported based on
   total bytes processed across all files.
   - Returns: A dictionary mapping airman identifiers to their records, and the
   non-fatal errors encountered while parsing (an empty array if none).
   */
  public func parse(
    files: [File] = File.allCases,
    progress: AsyncProgress? = nil
  ) async throws -> (airmen: AirmanDictionary, errors: [any Error]) {

    let db = AirmanDatabase()
    let errorLog = ErrorLog()

    let totalBytes = try calculateTotalFileSize(for: files)
    if let progress {
      await progress.setTotalBytes(totalBytes)
    }

    await withTaskGroup(of: Void.self) { group in
      for file in files {
        group.addTask { [self] in
          await parseFile(file, into: db, progress: progress, errorLog: errorLog)
        }
      }
    }

    if let progress {
      await progress.finish()
    }

    return (airmen: await db.merged(), errors: await errorLog.collect())
  }

  // Parses a single CSV file and adds airmen to the database
  private func parseFile(
    _ file: File,
    into database: AirmanDatabase,
    progress: AsyncProgress?,
    errorLog: ErrorLog
  ) async {
    let url = url(for: file)

    guard FileManager.default.fileExists(atPath: url.path) else {
      await errorLog.record(Errors.fileNotFound(url: url))
      return
    }

    do {
      let rowParserType = Self.rowParser[file]!
      let rowParser = rowParserType.init()

      let reader = ParallelCSVReader(url: url, delimiter: ",", quote: "\"", escape: "\"")

      let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
      let fileSize = Int64(fileAttributes[.size] as? Int ?? 0)

      let tracker = ProgressTracker(fileSize: fileSize, progress: progress)

      try await reader.processRows { [self] fields in
        await processRow(
          fields: fields,
          with: rowParser,
          into: database,
          tracker: tracker,
          errorLog: errorLog
        )
      }

      await tracker.finalize()
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

// Actor that safely manages progress updates for file parsing
private actor ProgressTracker {
  private var rowCount = 0
  private let updateInterval = 100
  private let fileSize: Int64
  private let progress: AsyncProgress?
  private var bytesReported: Int64 = 0

  init(fileSize: Int64, progress: AsyncProgress?) {
    self.fileSize = fileSize
    self.progress = progress
  }

  func incrementRow() async {
    rowCount += 1
    if rowCount.isMultiple(of: updateInterval) {
      if let progress {
        // Report progress proportional to rows processed
        // Assume average of 150 bytes per row (typical for FAA data)
        let bytesPerBatch: Int64 = 150 * Int64(updateInterval)
        let bytesToReport = min(bytesPerBatch, fileSize - bytesReported)
        if bytesToReport > 0 {
          await progress.addBytes(bytesToReport)
          bytesReported += bytesToReport
        }
      }
    }
  }

  func finalize() async {
    // Report any remaining bytes
    if let progress {
      let remaining = fileSize - bytesReported
      if remaining > 0 {
        await progress.addBytes(remaining)
      }
    }
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
