import ArgumentParser
import Foundation
@preconcurrency import Progress

@main
struct SwiftAirmenE2E: AsyncParsableCommand {
  @Option(
    name: .long,
    help: "The directory where data will be downloaded and unzipped.",
    completion: .directory,
    transform: { .init(filePath: $0) }
  )
  var workingDirectory = Process().currentDirectoryURL!

  func run() async throws {
    setupProgress()
    try await Runner().run()
  }

  private func setupProgress() {
    ProgressBar.defaultConfiguration = [
      ProgressPercent(decimalPlaces: 0),
      ProgressBarLine(),
      ProgressTimeEstimates()
    ]
  }
}
