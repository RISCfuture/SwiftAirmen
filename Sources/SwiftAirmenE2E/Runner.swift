import Foundation
import SwiftAirmen

class Runner {
    func run() async throws {
        print("Downloading…")
        let folder = try await download()

        print("Parsing…")
        let airmen = try await parse(folder: folder)

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
        return try await parser.parse(progress: progress) { print("Parsing error: \($0)") }
    }

    func testResult(airmen: Parser.AirmanDictionary) {
        let mostCerts = airmen.values.max { $0.certificates.count < $1.certificates.count }!
        print("\(mostCerts.debugDescription):\n\(mostCerts.certificates.map { "  \($0.description)" }.joined(separator: "\n"))")
    }
}
