import Foundation

/**
 Create an `AsyncProgress` instance to track progress with
 ``Parser/parse(files:progress:)``. Iterate its ``updates`` stream to receive a
 fresh ``Progress`` snapshot each time progress changes, or poll the
 ``completed`` and ``total`` properties.

 Progress is tracked based on the total number of bytes across all CSV files
 being parsed, providing a unified progress view when processing multiple files
 in parallel.

 Example:

 ``` swift
 let progress = AsyncProgress()
 let monitor = Task {
   for await snapshot in progress.updates {
     print("Progress: \(snapshot.percentDone)%")
   }
 }
 let (airmen, errors) = try await parser.parse(files: myFiles, progress: progress)
 await monitor.value
 ```
 */
public actor AsyncProgress {
  private var totalBytes: Int64 = 0
  private var completedBytes: Int64 = 0
  private let continuation: AsyncStream<Progress>.Continuation

  /// A stream of ``Progress`` snapshots, emitting a new value each time
  /// ``completed`` or ``total`` changes and finishing when the operation
  /// completes.
  nonisolated public let updates: AsyncStream<Progress>

  /// The expected total number of bytes to parse.
  public var total: Int64 { totalBytes }

  /// The number of bytes parsed so far.
  public var completed: Int64 { completedBytes }

  /// `true` when the operation is completed.
  public var isFinished: Bool { completed == total }

  /// `true` if the total number of operations has not been determined yet.
  public var isIndeterminate: Bool { total == 0 }

  /// A snapshot of the current progress.
  public var progress: Progress { .init(completed, of: total) }

  /// The ratio of completed operations to total operations. `nil` if
  /// ``isIndeterminate`` is true.
  public var fractionDone: Double? {
    guard total != 0 else { return nil }
    return Double(completed) / Double(total)
  }

  /// The ``fractionDone``, expressed as a percentage. `nil` if
  /// ``isIndeterminate`` is true.
  public var percentDone: Double? {
    guard let fractionDone else { return nil }
    return fractionDone * 100
  }

  /// Designated initializer.
  public init() {
    (updates, continuation) = AsyncStream<Progress>.makeStream()
  }

  func setTotalBytes(_ bytes: Int64) {
    totalBytes = bytes
    continuation.yield(progress)
  }

  func addBytes(_ bytes: Int64) {
    completedBytes = min(completedBytes + bytes, totalBytes)
    continuation.yield(progress)
  }

  func finish() {
    continuation.yield(progress)
    continuation.finish()
  }
}
