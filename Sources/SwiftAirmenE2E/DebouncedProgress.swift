import Foundation
import Observation
import Progress

// Renders a `ProgressManager` to a terminal progress bar, throttled to one
// update per second, always rendering the final value.
//
// `ProgressManager` is `Observable`, so the bar follows it by observation
// instead of polling on a timer. `Observations.untilFinished` ends the sequence
// on its own once the manager reports finished.
actor DebouncedProgress {
  private static let renderInterval: TimeInterval = 1

  private var progressBar: ProgressBar?
  private var lastRenderAt = Date.distantPast

  func track(_ progress: ProgressManager) async {
    let snapshots = Observations.untilFinished {
      () -> Observations<Snapshot, Never>.Iteration in
      progress.isFinished
        ? .finish
        : .next(Snapshot(completed: progress.completedCount, total: progress.totalCount))
    }

    var latest: Snapshot?
    for await snapshot in snapshots {
      latest = snapshot
      if shouldRender() { render(snapshot) }
    }
    render(Snapshot(completed: latest?.total ?? 1, total: latest?.total ?? 1))
  }

  private func shouldRender() -> Bool {
    let now = Date()
    guard now.timeIntervalSince(lastRenderAt) >= Self.renderInterval else { return false }
    lastRenderAt = now
    return true
  }

  private func render(_ snapshot: Snapshot) {
    // An indeterminate manager has no total to size the bar against.
    guard let total = snapshot.total, total > 0 else { return }
    if progressBar?.count != total {
      progressBar = ProgressBar(count: total)
    }
    progressBar?.setValue(snapshot.completed)
  }

  private struct Snapshot: Sendable {
    let completed: Int
    let total: Int?
  }
}
