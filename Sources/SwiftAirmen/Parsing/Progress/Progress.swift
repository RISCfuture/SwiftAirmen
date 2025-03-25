import Foundation

/// Represents the progress of a parsing operation.
public actor Progress {

    /// The number of records already parsed.
    public let completed: Int64

    /// The total number of records to be parsed.
    public let total: Int64

    /// `true` if the completed and total values are the same.
    public var isFinished: Bool { completed == total }

    /// The ratio of completed operations to total operations.
    public var fractionDone: Double { Double(completed) / Double(total) }

    /// The ``fractionDone``, expressed as a percentage.
    public var percentDone: Double { fractionDone * 100 }

    init(_ completed: Int64, of total: Int64) {
        self.completed = completed
        self.total = total
    }
}
