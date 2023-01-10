import Foundation

/**
 Downloads the airmen certificate registry from the FAA in CSV format. See
 https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download/
 for more information about the structure and contents of the file.
 
 If you wish to use `async`/`await` syntax, use the ``download()`` method, which
 returns a file URL. Otherwise, use the ``download(callback:)`` method, to which
 you provide a callback that receives the URL.
 
 The file downloaded by this class can be used by ``Parser`` to parse airmen
 records. See <doc:GettingStarted> for an example.
 
 New airmen database editions are released monthly, named with the format
 `MMYYYY`.
 */
public class Downloader {
    
    /// A callback that `Downloader` uses to report progress.
    public typealias ProgressCallback = (Progress) -> Void
    
    private static let urlFormat = "https://registry.faa.gov/database/CS%{M}%{Y}.zip"
    private static let calendar = Calendar(identifier: .gregorian)
    
    private let date: Date
    let progressCallback: ProgressCallback?
    let session = URLSession(configuration: .ephemeral)
    let workingDirectory: URL
    
    /**
     Creates a new instance that will download airmen data for a given date.
     
     - Parameter date: The effective date of the airmen database (default
     today). The month and year portion of this date are used to select the
     effective database edition.
     - Parameter workingDirectory: The directory the file will be downloaded and
     unzipped to. Defaults to a temporary directory.
     - Parameter progressCallback: A callback that the downloader will report
     progress to.
     */
    public init(date: Date? = nil, workingDirectory: URL? = nil, progressCallback: ProgressCallback? = nil) throws {
        self.date = date ?? Date()
        self.progressCallback = progressCallback
        self.workingDirectory = try workingDirectory ??
        FileManager.default.url(for: .itemReplacementDirectory,
                                in: .userDomainMask,
                                appropriateFor: FileManager.default.temporaryDirectory,
                                create: true)
    }
    
    func dataURL() -> URL {
        let components = Self.calendar.dateComponents([.month, .year], from: date)
        guard let month = components.month,
              let year = components.year else {
            fatalError("Couldn’t get month/year from date \(date).")
        }
        let monthStr = String(format: "%02d", month)
        let yearStr = String(format: "%04d", year)
        
        let url = Self.urlFormat.replacingOccurrences(of: "%{M}", with: monthStr)
            .replacingOccurrences(of: "%{Y}", with: yearStr)
        
        return URL(string: url)!
    }
    
    func zipfileLocation() -> URL {
        if #available(macOS 13.0, *) {
            return workingDirectory.appending(component: zipfileName(), directoryHint: .notDirectory)
        } else {
            return workingDirectory.appendingPathComponent(zipfileName(), isDirectory: false)
        }
    }
    
    func folderLocation() -> URL {
        if #available(macOS 13.0, *) {
            return workingDirectory.appending(component: folderName(), directoryHint: .isDirectory)
        } else {
            return workingDirectory.appendingPathComponent(zipfileName(), isDirectory: true)
        }
    }
    
    private func zipfileName() -> String { dataURL().lastPathComponent }
    
    private func folderName() -> String { dataURL().deletingPathExtension().lastPathComponent }
}


