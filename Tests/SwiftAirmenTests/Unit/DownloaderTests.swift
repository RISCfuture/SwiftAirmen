import Foundation
import Testing
import ZIPFoundation

@testable import SwiftAirmen

@Suite
struct `Downloader tests` {

  let testResourcesURL = Bundle.module.resourceURL!
    .appendingPathComponent("TestResources")

  private func makeDownloaderWithZippedFixture() throws -> Downloader {
    let workingDirectory = try FileManager.default.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: FileManager.default.temporaryDirectory,
      create: true
    )
    let downloader = try Downloader(
      date: DateComponents(calendar: .init(identifier: .gregorian), year: 2024, month: 1).date,
      workingDirectory: workingDirectory
    )

    let fixture = testResourcesURL.appendingPathComponent("PILOT_BASIC.csv")
    try FileManager.default.zipItem(
      at: fixture,
      to: downloader.zipfileLocation(),
      shouldKeepParent: false
    )
    return downloader
  }

  @Test
  func `builds the archive URL with a zero-padded month and four-digit year`() throws {
    let downloader = try Downloader(
      date: DateComponents(calendar: .init(identifier: .gregorian), year: 2024, month: 1).date,
      workingDirectory: FileManager.default.temporaryDirectory
    )

    #expect(
      downloader.dataURL().absoluteString == "https://registry.faa.gov/database/CS012024.zip"
    )
  }

  @Test
  func `unzips a downloaded archive`() throws {
    let downloader = try makeDownloaderWithZippedFixture()

    let extractedFolder = try downloader.unzip(url: downloader.zipfileLocation())
    #expect(extractedFolder == downloader.folderLocation())

    let extractedFile = extractedFolder.appendingPathComponent("PILOT_BASIC.csv")
    let fixture = testResourcesURL.appendingPathComponent("PILOT_BASIC.csv")
    #expect(try Data(contentsOf: extractedFile) == Data(contentsOf: fixture))
  }

  @Test
  func `overwrites a previously-extracted folder when unzipping`() throws {
    let downloader = try makeDownloaderWithZippedFixture()

    _ = try downloader.unzip(url: downloader.zipfileLocation())
    _ = try downloader.unzip(url: downloader.zipfileLocation())
  }
}
