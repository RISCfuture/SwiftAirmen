import Foundation
import StreamingCSV

/**
 Parses an airman certification database into memory. The database must be
 downloaded in CSV format and stored, unarchived, in a directory somewhere
 accessible. The names of the CSV files must not be changed.
 
 The parser uses parallel processing at two levels:
 
 - Multiple CSV files are processed concurrently
 - Each individual CSV file is parsed using parallel chunk processing
 
 This provides significant performance improvements when parsing the full
 airman database.
 
 Call the ``parse(files:progress:errorCallback:)`` method to parse the airman
 database. The method uses Swift's async/await concurrency and returns an
 ``AirmanDictionary``.
 
 You can use ``Downloader`` to download the CSV file automatically. See
 <doc:GettingStarted> for an example.
 */
public final class Parser: Sendable {
    /**
     Return value for all `parse` methods. A dictionary mapping an airman's
     unique ID (such as `A4760216`) to the ``Airman`` record, which contains all
     data loaded for that airman.
     */
    public typealias AirmanDictionary = [String: Airman]

    /**
     Callback used for all `parse` methods; called when an error occurs during
     parsing. Parsing does not stop; the error is reported and parsing
     continues.
     
     - Parameter error: The parsing error that occurred.
     */
    public typealias ErrorCallback = @Sendable (_ error: Error) -> Void

    /**
     Callback used to report progress during parsing operations.
     
     - Parameter progress: The progress of the parsing operation.
     */
    public typealias ProgressCallback = @Sendable (Progress) -> Void

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
     
     Errors do not stop parsing; they are given to you via `errorCallback` and the row is skipped.
     
     - Parameter files: The files to parse. This array should be unique,
     otherwise parsing will be unnecessarily slower.
     - Parameter progress: Create an instance of ``AsyncProgress`` and pass it
     here if you wish to track parsing progress. Progress is reported based on
     total bytes processed across all files.
     - Parameter errorCallback: Called when an error occurs during row parsing.
     Parsing does not halt.
     - Returns: A dictionary mapping airman identifiers to their records.
     */
    public func parse(files: [File] = File.allCases,
                      progress: AsyncProgress?,
                      errorCallback: @escaping ErrorCallback) async throws -> AirmanDictionary {

        let db = AirmanDatabase()

        // Calculate total bytes across all files
        let totalBytes = try calculateTotalFileSize(for: files)

        // Set total bytes for progress tracking
        if let progress {
            await progress.setTotalBytes(totalBytes)
        }

        // Process all files in parallel
        await withTaskGroup(of: Void.self) { group in
            for file in files {
                group.addTask { [self] in
                    await parseFile(file, into: db, progress: progress, errorCallback: errorCallback)
                }
            }
        }

        return await db.merged()
    }

    // Parses a single CSV file and adds airmen to the database
    private func parseFile(_ file: File,
                           into database: AirmanDatabase,
                           progress: AsyncProgress?,
                           errorCallback: @escaping ErrorCallback) async {
        let url = url(for: file)

        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorCallback(Errors.fileNotFound(url: url))
            return
        }

        do {
            let rowParserType = Self.rowParser[file]!
            let rowParser = rowParserType.init()

            // Create parallel reader
            let reader = ParallelCSVReader(url: url, delimiter: ",", quote: "\"", escape: "\"")

            // Get file size for progress estimation
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = Int64(fileAttributes[.size] as? Int ?? 0)

            // Create progress tracker for this file
            let tracker = ProgressTracker(fileSize: fileSize, progress: progress)

            // Process rows with batched progress tracking
            try await reader.processRows { [self] fields in
                await processRow(fields: fields,
                                 with: rowParser,
                                 into: database,
                                 tracker: tracker,
                                 errorCallback: errorCallback)
            }

            // Ensure all progress is reported for this file
            await tracker.finalize()
        } catch {
            errorCallback(error)
        }
    }

    // Processes a single CSV row
    private func processRow(fields: [String],
                            with rowParser: any RowParser,
                            into database: AirmanDatabase,
                            tracker: ProgressTracker,
                            errorCallback: @escaping ErrorCallback) async {
        await tracker.incrementRow()

        do {
            if let airman = try rowParser.parse(fields: fields) {
                await database.append(airman: airman)
            }
        } catch {
            errorCallback(error)
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
