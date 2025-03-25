import CSV
import Foundation

/**
 Parses an airman certification database into memory. The database must be
 downloaded in CSV format and stored, unarchived, in a directory somewhere
 accessible. The names of the CSV files must not be changed.
 
 If you wish to use `async`/`await` syntax, call the
 ``parse(files:progress:errorCallback:)`` method. If you wish to use Combine,
 call the ``parse(files:)`` method. Otherwise, use the
 ``parse(files:callback:progressCallback:errorCallback:)`` method. All three
 methods take a `URL` to the downloaded and unzipped CSV file, and return (or
 yield) an ``AirmanDictionary``.
 
 You can use ``Downloader`` to download the CSV file automatically. See
 <doc:GettingStarted> for an example.
 */
public final class Parser: Sendable {
    typealias ParseCallback = ((_ paeser: CSVParser) throws -> Airman?)
    typealias ParseResultCallback = (_ result: Array<Airman>) -> Void

    /**
     Return value for all `parse` methods. A dictionary mapping an airman's
     unique ID (such as `A4760216`) to the ``Airman`` record, which contains all
     data loaded for that airman.
     */
    public typealias AirmanDictionary = [String: Airman]

    /**
     Callback used for ``parse(files:callback:progressCallback:errorCallback:)``;
     called when parsing is finished.
     
     - Parameter airmen: A dictionary mapping airmen record IDs to `Airmen`
     records.
     */
    public typealias ResultCallback = (_ airmen: AirmanDictionary) -> Void

    /**
     Callback used for all `parse` methods; called when an error occurs during
     parsing. Parsing does not stop; the error is reported and parsing
     continues.
     
     - Parameter error: The parsing error that occurred.
     */
    public typealias ErrorCallback = @Sendable (_ error: Error) -> Void

    /**
     Callback used to report progress durinbg an asynchronous parsing operation.
     
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

    func countLines(in url: URL) throws -> Int64 {
        let data = try String(contentsOf: url, encoding: .ascii)
        var count: Int64 = 0
        data.enumerateLines { _, _ in count += 1 }
        return count
    }

    func url(for file: File) -> URL {
        directory.appendingPathComponent(file.rawValue)
    }

    /**
     Parses all airmen records in one or more files. Errors do not stop parsing;
     they are given to you via `errorCallback` and the row is skipped.

     - Parameter files: The files to parse. This array should be unique,
     otherwise parsing will be unnecessarily slower.
     - Parameter progress: Create an instance of ``AsyncProgress`` and pass it
     here if you wish to track parsing progress.
     - Parameter errorCallback: Called when an error occurs during row parsing.
     Parsing does not halt.
     - Returns: A dictionary mapping airman identifiers to their records.
     */
    public func parse(files: [File] = File.allCases,
                      progress: AsyncProgress?,
                      errorCallback: @escaping ErrorCallback) async throws -> AirmanDictionary {
        let db = await withThrowingTaskGroup(of: Void.self, returning: AirmanDatabase.self) { group in
            let db = AirmanDatabase()

            for file in files {
                group.addTask {
                    let rowParserType = Self.rowParser[file]!
                    let rowParser = rowParserType.init()

                    let airmen = try await self.parse(file: file, parseCallback: { parser in
                        try rowParser.parse(parser: parser)
                    }, progress: progress, errorCallback: errorCallback)
                    for try await airman in airmen {
                        await db.append(airman: airman)
                    }
                }
            }

            return db
        }

        return await db.merged()
    }

    private func parse(file: File,
                       parseCallback: @escaping ParseCallback,
                       progress: AsyncProgress?,
                       errorCallback _: @escaping ErrorCallback) async throws -> AirmanSequence {
        let url = self.url(for: file)
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        let total = try countLines(in: url)
        if let progress { await progress.update(file: file, total: total) }

        return AirmanSequence(parseCallback: parseCallback, parser: parser, file: file, progress: progress)
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

    private struct AirmanSequence: AsyncSequence, AsyncIteratorProtocol {
        typealias Element = Airman

        let parseCallback: ParseCallback
        let parser: CSVParser
        let file: File
        let progress: AsyncProgress?

        func makeAsyncIterator() -> Self { self }

        func next() async throws -> Airman? {
            await progress?.increment(file: file)
            return try parseCallback(parser)
        }
    }
}
