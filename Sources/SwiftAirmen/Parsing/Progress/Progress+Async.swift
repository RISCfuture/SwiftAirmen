import Foundation

/**
 Create an `AsyncProgress` instance to track progress with
 ``Parser/parse(files:progress:errorCallback:)``. You can query the
 ``completed`` and ``total`` properties on a timer to update your UI.
 
 Progress is tracked based on the total number of bytes across all CSV files
 being parsed, providing a unified progress view when processing multiple files
 in parallel.
 
 Example:
 
 ``` swift
 let progress = AsyncProgress()
 Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
   guard let percent = await progress.percentDone else { return }
   print("Progress: \(percent)%")
 }
 try await parser.parse(files: myFiles, progress: progress, errorCallback: { _ in })
 ```
 */
public actor AsyncProgress {
    private var totalBytes: Int64 = 0 {
        didSet {
            if let callback { callback(progress) }
        }
    }

    private var completedBytes: Int64 = 0 {
        didSet {
            if let callback { callback(progress) }
        }
    }

    /// An optional callback that is invoked any time ``completed`` or ``total``
    /// changes.
    public var callback: Parser.ProgressCallback?

    /// The expected total number of bytes to parse.
    public var total: Int64 { totalBytes }

    /// The number of bytes parsed so far.
    public var completed: Int64 { completedBytes }

    /// `true` when the operation is completed.
    public var isFinished: Bool { completed == total }

    /// `true` if the total number of operations has not been determined yet.
    public var isIndeterminate: Bool { total == 0 }

    /// An object representing the current progress.
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

    /**
     Designated initializer.

     - Parameter callback: A value for ``callback``.
     */
    public init(callback: Parser.ProgressCallback? = nil) {
        self.callback = callback
    }

    func setTotalBytes(_ bytes: Int64) {
        totalBytes = bytes
    }

    func addBytes(_ bytes: Int64) {
        completedBytes = min(completedBytes + bytes, totalBytes)
    }
}
