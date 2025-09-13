import Foundation

// Helper classes for thread-safe error collection in tests
final class ErrorCollector: @unchecked Sendable {
    private var _errors: [Error] = []
    private let lock = NSLock()

    var errors: [Error] {
        lock.lock()
        defer { lock.unlock() }
        return _errors
    }

    func add(_ error: Error) {
        lock.lock()
        defer { lock.unlock() }
        _errors.append(error)
    }
}

final class ErrorCounter: @unchecked Sendable {
    private var _count = 0
    private let lock = NSLock()

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _count
    }

    var isEmpty: Bool { count == 0 } // swiftlint:disable:this empty_count

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        _count += 1
    }
}
