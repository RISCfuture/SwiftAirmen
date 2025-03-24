import Foundation

/**
 Create an `AsyncProgress` instance to track progress with
 ``Parser/parse(files:progress:errorCallback:)``. You can query the
 ``completed`` and ``total`` properties on a timer to update your UI.
 
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
    private var totals = Dictionary<Parser.File, Int64>() {
        didSet {
            if let callback { callback(progress) }
        }
    }
    
    private var counts = Dictionary<Parser.File, Int64>() {
        didSet {
            if let callback { callback(progress) }
        }
    }
    
    /// An optional callback that is invoked any time ``completed`` or ``total``
    /// changes.
    public var callback: Parser.ProgressCallback? = nil
    
    /**
     Designated initializer.
     
     - Parameter callback: A value for ``callback``.
     */
    public init(callback: Parser.ProgressCallback? = nil) {
        self.callback = callback
    }
    
    /// The expected total number of records to parse.
    public var total: Int64 { totals.values.reduce(0, +) }
    
    /// The number of records parsed so far.
    public var completed: Int64 { counts.values.reduce(0, +) }
    
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
        guard let fractionDone = fractionDone else { return nil }
        return fractionDone * 100
    }
    
    func update(file: Parser.File, completed: Int64? = nil, total: Int64? = nil) {
        if counts.keys.contains(file) {
            if let completed { counts[file] = completed }
            if let total { totals[file] = total }
        } else if let total {
            totals[file] = total
            counts[file] = completed ?? 0
        }
    }
    
    func increment(file: Parser.File) {
        guard counts.keys.contains(file) else { return }
        counts[file] = counts[file]! + 1
    }
}

