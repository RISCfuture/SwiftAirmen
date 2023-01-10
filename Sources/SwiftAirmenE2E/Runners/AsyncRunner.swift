import Foundation
import SwiftAirmen

@available(macOS 13.0, *)
class AsyncRunner: Runner {
    func run() async throws {
        print("Downloading…")
        let folder = try await download()
        
        print("Parsing…")
        let airmen = try await parse(folder: folder)
        
        testResult(airmen: airmen)
    }
    
    private func download() async throws -> URL {
        let bar = DebouncedProgress()
        bar.start()
        defer { bar.stop() }
        
        let downloader = try Downloader() { bar.progress = $0 }
        return try await downloader.download()
    }
    
    private func parse(folder: URL) async throws -> Dictionary<String, Airman> {
        let bar = DebouncedProgress()
        bar.start()
        defer { bar.stop() }
        
        let parser = Parser(directory: folder)
        let progress = AsyncProgress() { bar.progress = $0 }
        return try await parser.parse(progress: progress, errorCallback: { print("Parsing error: \($0)") })
    }
}
