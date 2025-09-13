import Foundation
import SwiftAirmen

class Runner {
    func run() async throws {
        print("Downloading…")
        let folder = try await download()

        print("Processing…")
        let startTime = Date()
        let airmen = try await parse(folder: folder)
        let parseTime = Date().timeIntervalSince(startTime)

        print("Statistics")
        print("  Total airmen: \(airmen.count)")
        print("  Processing time: \(String(format: "%.2f", parseTime)) seconds")
        print("")

        testResult(airmen: airmen)
    }

    private func download() async throws -> URL {
        let bar = DebouncedProgress()
        await bar.start()
        defer { Task { await bar.stop() } }

        let downloader = try Downloader { progress in Task { await bar.setProgress(progress) } }
        return try await downloader.download()
    }

    private func parse(folder: URL) async throws -> [String: Airman] {
        let bar = DebouncedProgress()
        await bar.start()
        defer { Task { await bar.stop() } }

        let parser = Parser(directory: folder)
        let progress = AsyncProgress { progress in Task { await bar.setProgress(progress) } }

        final class ErrorCounter: @unchecked Sendable {
            private var count = 0
            private let lock = NSLock()

            func handleError(_ error: Error) {
                lock.lock()
                defer { lock.unlock() }
                count += 1
                if count <= 10 {  // Only print first 10 errors to avoid spam
                    print("⚠️ Parsing error: \(error)")
                }
            }

            func printSummary() {
                if count > 10 {
                    print("⚠️ ... and \(count - 10) more errors")
                }
            }
        }

        let errorCounter = ErrorCounter()
        let airmen = try await parser.parse(progress: progress, errorCallback: errorCounter.handleError)
        errorCounter.printSummary()

        return airmen
    }

    func testResult(airmen: Parser.AirmanDictionary) {
        let mostCerts = airmen.values.max { $0.certificates.count < $1.certificates.count }!
        print("Airman with most certificates:")
        print("\(mostCerts.debugDescription):\n\(mostCerts.certificates.map { "  \($0.description)" }.joined(separator: "\n"))")
    }
}
