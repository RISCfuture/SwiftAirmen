import Foundation
import Progress
import SwiftAirmen

actor DebouncedProgress {
  private static let renderInterval: TimeInterval = 1

  private var progressBar: ProgressBar?
  private var lastRenderAt = Date.distantPast

  // Renders progress snapshots from the stream, throttled to one update per
  // second, always rendering the final value.
  func track(_ stream: AsyncStream<SwiftAirmen.Progress>) async {
    var latest: SwiftAirmen.Progress?
    for await progress in stream {
      latest = progress
      if shouldRender() { render(progress) }
    }
    if let latest { render(latest) }
  }

  private func shouldRender() -> Bool {
    let now = Date()
    guard now.timeIntervalSince(lastRenderAt) >= Self.renderInterval else { return false }
    lastRenderAt = now
    return true
  }

  private func render(_ progress: SwiftAirmen.Progress) {
    let total = Int(progress.total)
    if progressBar?.count != total {
      progressBar = ProgressBar(count: total)
    }
    progressBar?.setValue(Int(progress.completed))
  }
}
