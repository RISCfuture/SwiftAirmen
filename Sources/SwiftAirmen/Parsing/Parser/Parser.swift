import Foundation
import Dispatch
import CSV

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
public class Parser {
    typealias ParseCallback = ((_ paeser: CSVParser) throws -> Airman?)
    typealias ParseResultCallback = (_ result: Array<Airman>) -> Void
    
    /**
     Return value for all `parse` methods. A dictionary mapping an airman's
     unique ID (such as `A4760216`) to the ``Airman`` record, which contains all
     data loaded for that airman.
     */
    public typealias AirmanDictionary = Dictionary<String, Airman>
    
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
    public typealias ErrorCallback = (_ error: Error) -> Void
    
    /**
     Callback used to report progress durinbg an asynchronous parsing operation.
     
     - Parameter progress: The progress of the parsing operation.
     */
    public typealias ProgressCallback = (Progress) -> Void
    
    /// The directory that the parser will look for CSV files in.
    public let directory: URL
    
    /// The GCD queue that will be used for parsing operations.
    public var queue = DispatchQueue(label: "codes.tim.SwiftAirmen", qos: .background, attributes: [.concurrent])
    private let airmenSemaphore = DispatchSemaphore(value: 1)
    
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
    
    /// A CSV file within an airman database distribution to parse.
    public enum File: String, CaseIterable {
        
        /// Parse the `PILOT_BASIC.csv` file.
        case pilotBasic = "PILOT_BASIC.csv"
        
        /// Parse the `NONPILOT_BASIC.csv` file.
        case nonpilotBasic = "NONPILOT_BASIC.csv"
        
        /// Parse the `PILOT_CERT.csv` file.
        case pilotCert = "PILOT_CERT.csv"
        
        /// Parse the `NONPILOT_CERT.csv` file.
        case nonPilotCert = "NONPILOT_CERT.csv"
    }
    
    static let rowParser: Dictionary<File, any RowParser.Type> = [
        .pilotBasic: BasicRowParser.self,
        .nonpilotBasic: BasicRowParser.self,
        .pilotCert: PilotCertRowParser.self,
        .nonPilotCert: NonPilotCertRowParser.self
    ]
}
