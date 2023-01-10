import Foundation
import CSV

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Parser {
    
    /**
     Parses all airmen records in one or more files. Errors do not stop parsing;
     they are given to you via `errorCallback` and the row is skipped.
     
     - Parameter files: The files to parse. This array should be unique,
     otherwise parsing will be unnecessarily slower.
     - Parameter progress: Create an instance of ``AsyncProgress`` and pass it
     here if you wish to track parsing progress.
     - Parameter errorCallback: Called when an error occurs during row parsing.
     Parsing does not halt.
     - Returns: A dictionary mapping airman identifiers to their records.
     */
    public func parse(files: Array<File> = File.allCases,
                      progress: AsyncProgress?,
                      errorCallback: @escaping ErrorCallback) async throws -> AirmanDictionary {
        let db = await withThrowingTaskGroup(of: Void.self, returning: AirmanDatabase.self) { group in
            let db = AirmanDatabase()
            
            for file in files {
                group.addTask {
                    let rowParserType = Self.rowParser[file]!
                    let rowParser = rowParserType.init()
                    
                    let airmen = try await self.parse(file: file, parseCallback: {
                        try rowParser.parse(parser: $0)
                    }, progress: progress, errorCallback: errorCallback)
                    for try await airman in airmen {
                        db.append(airman: airman)
                    }
                }
            }
            
            return db
        }
        
        return await withCheckedContinuation { continuation in
            db.merged { continuation.resume(returning: $0) }
        }
    }
    
    private func parse(file: File,
                       parseCallback: @escaping ParseCallback,
                       progress: AsyncProgress?,
                       errorCallback: @escaping ErrorCallback) async throws -> AirmanSequence {
        let url = self.url(for: file)
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        let total = try countLines(in: url)
        if let progress = progress { await progress.update(file: file, total: total) }
        
        return AirmanSequence(parseCallback: parseCallback, parser: parser, file: file, progress: progress)
    }
    
    private struct AirmanSequence: AsyncSequence, AsyncIteratorProtocol {
        typealias Element = Airman
        
        let parseCallback: ParseCallback
        let parser: CSVParser
        let file: File
        let progress: AsyncProgress?
        
        func makeAsyncIterator() -> Self { self }
        
        func next() async throws -> Airman? {
            await progress?.increment(file: file)
            return try parseCallback(parser)
        }
    }
}

