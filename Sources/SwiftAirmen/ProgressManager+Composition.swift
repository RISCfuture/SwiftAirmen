import Foundation

extension ProgressManager {

  /// Creates a child manager contributing `count` units toward this manager's
  /// total.
  ///
  /// The child is wired in through its ``ProgressManager/reporter`` rather than
  /// by handing it a `Subprogress`, because a `Subprogress` is noncopyable and
  /// so cannot be captured by the escaping closure of a concurrently-running
  /// task. A `ProgressManager` is a `Sendable` class and crosses freely.
  ///
  /// - Parameters:
  ///   - count: The portion of this manager's total the child accounts for.
  ///   - totalCount: The child's own total. Pass `nil` when it isn't known yet
  ///     and set it later with ``setTotalCount(_:)``.
  /// - Returns: The newly-attached child.
  func child(assigningCount count: Int, totalCount: Int? = nil) -> ProgressManager {
    let child = ProgressManager(totalCount: totalCount)
    assign(count: count, to: child.reporter)
    return child
  }

  /// Sets the total unit count once it becomes known, leaving the completed
  /// count as it stands.
  ///
  /// - Parameter count: The new total, or `nil` to become indeterminate.
  func setTotalCount(_ count: Int?) {
    setCounts { _, total in total = count }
  }

  /// Records `count` as the absolute number of units completed, widening the
  /// total when the work turns out larger than advertised.
  ///
  /// `ProgressManager/complete(count:)` does not clamp, so a source that
  /// under-reports its size (an HTTP `Content-Length` that undercounts the body,
  /// say) would otherwise drive ``fractionCompleted`` past 1.0.
  ///
  /// - Parameter count: Units completed so far, counted from zero.
  func setCompletedCount(_ count: Int) {
    setCounts { completed, total in
      completed = count
      if let known = total, known < count { total = count }
    }
  }

  /// Marks every remaining unit complete.
  ///
  /// Used to settle a leg whose incremental reports are approximate, so the
  /// leg reads as finished even when its increments didn't sum to the total.
  func finish() {
    setCounts { completed, total in completed = total ?? completed }
  }
}
