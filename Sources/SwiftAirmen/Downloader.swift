public import Foundation
import ZIPFoundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Downloads the airmen certificate registry from the FAA in CSV format. See
/// https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download/
/// for more information about the structure and contents of the file.
///
/// Use the ``download(progress:)`` method to download the airmen database. This
/// method uses Swift's async/await and returns a file URL pointing to the
/// extracted CSV files. To observe download progress, hand it a `Subprogress`
/// from your own `ProgressManager`.
///
/// The file downloaded by this class can be used by ``Parser`` to parse airmen
/// records. See <doc:GettingStarted> for an example.
///
/// New airmen database editions are released monthly, named with the format
/// `MMYYYY`.
public class Downloader {

  private static let dataURLTemplate = URL.Template(
    "https://registry.faa.gov/database/CS{month}{year}.zip"
  )!
  private static let calendar = Calendar(identifier: .gregorian)
  private static let progressReportInterval = 1 << 20

  private let date: Date
  let session = URLSession(configuration: .ephemeral)
  let workingDirectory: URL

  /**
   Creates a new instance that will download airmen data for a given date.

   - Parameter date: The effective date of the airmen database (default
   today). The month and year portion of this date are used to select the
   effective database edition.
   - Parameter workingDirectory: The directory the file will be downloaded and
   unzipped to. Defaults to a temporary directory.
   */
  public init(
    date: Date? = nil,
    workingDirectory: URL? = nil
  ) throws {
    self.date = date ?? Date()
    self.workingDirectory =
      try workingDirectory
      ?? FileManager.default.url(
        for: .itemReplacementDirectory,
        in: .userDomainMask,
        appropriateFor: FileManager.default.temporaryDirectory,
        create: true
      )
  }

  func dataURL() -> URL {
    let components = Self.calendar.dateComponents([.month, .year], from: date)
    guard let month = components.month,
      let year = components.year
    else {
      fatalError("Couldn’t get month/year from date \(date).")
    }

    return URL(
      template: Self.dataURLTemplate,
      variables: [
        .init("month"): .text(unsafe String(format: "%02d", month)),
        .init("year"): .text(unsafe String(format: "%04d", year))
      ]
    )!
  }

  func zipfileLocation() -> URL {
    workingDirectory.appending(component: zipfileName(), directoryHint: .notDirectory)
  }

  func folderLocation() -> URL {
    workingDirectory.appending(component: folderName(), directoryHint: .isDirectory)
  }

  private func zipfileName() -> String { dataURL().lastPathComponent }

  private func folderName() -> String { dataURL().deletingPathExtension().lastPathComponent }

  /**
   Downloads and unzips the airmen database to a directory. This directory can
   be used by ``Parser`` to return airmen records.

   - Parameter progress: Optional progress sink, reporting bytes received. Stays
   indeterminate until the server declares a content length.
   - Returns: The URL of the downloaded airmen database.
   */
  public func download(progress: consuming Subprogress? = nil) async throws -> URL {
    let zipfile = try await _download(progress: progress?.start(totalCount: nil))
    return try unzip(url: zipfile)
  }

  private func _download(progress: ProgressManager?) async throws -> URL {
    let request = URLRequest(url: dataURL())
    let data = try await fetch(request, progress: progress)

    try data.write(to: zipfileLocation())
    progress?.finish()
    return zipfileLocation()
  }

  private func validate(_ response: URLResponse, for request: URLRequest) throws -> HTTPURLResponse
  {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw Errors.networkError(request: request, response: response)
    }
    guard httpResponse.statusCode / 100 == 2 else {
      throw Errors.networkError(request: request, response: response)
    }
    return httpResponse
  }

  // `URLSession.bytes(for:)` isn’t available in FoundationNetworking, so Linux falls back to a
  // single-shot download without incremental progress.
  #if canImport(Darwin)
    private func fetch(_ request: URLRequest, progress: ProgressManager?) async throws -> Data {
      let (bytes, response) = try await session.bytes(for: request)
      let httpResponse = try validate(response, for: request)

      let total = httpResponse.expectedContentLength
      if total > 0 {
        progress?.setTotalCount(Int(total))
        progress?.totalByteCount = UInt64(total)
      }
      var data = Data(capacity: Int(total))
      var countAtLastReport = 0

      // Reporting once per megabyte rather than once per byte keeps observing a
      // multi-hundred-megabyte archive from costing an update per byte.
      func report() {
        countAtLastReport = data.count
        progress?.setCompletedCount(data.count)
        progress?.completedByteCount = UInt64(data.count)
      }

      for try await byte in bytes {
        data.append(byte)
        if data.count - countAtLastReport >= Self.progressReportInterval { report() }
      }
      if data.count != countAtLastReport { report() }
      return data
    }
  #else
    private func fetch(_ request: URLRequest, progress: ProgressManager?) async throws -> Data {
      let (data, response) = try await session.data(for: request)
      _ = try validate(response, for: request)
      // One indivisible unit: without a streaming API there is nothing to
      // report until the whole body has arrived.
      progress?.totalByteCount = UInt64(data.count)
      progress?.completedByteCount = UInt64(data.count)
      progress?.setTotalCount(1)
      progress?.setCompletedCount(1)
      return data
    }
  #endif

  func unzip(url: URL) throws -> URL {
    let destination = folderLocation()
    try? FileManager.default.removeItem(at: destination)
    try FileManager.default.unzipItem(at: url, to: destination)
    return destination
  }
}
