import Foundation
import Dispatch
import CSV

extension Parser {
    
    /**
     Parses all airman records in one or more CSV files. Parsing executes
     asynchronously, and the results are returned to `callback` when completed.
     Errors do not stop parsing; they are given back to you via `errorCallback`
     and the row is skipped.
     
     - Parameter files: The files to parse. This array should be unique,
     otherwise parsing will be unnecessarily slower.
     - Parameter callback: Executed when parsing is completed.
     - Parameter progressCallback: Called when a row is parsed. This blocks when
     executed, so it should be efficiently implemented.
     - Parameter errorCallback: Called when an error occurs during row parsing.
     Parsing does not halt.
     */
    public func parse(files: Array<File> = File.allCases,
                      callback: @escaping ResultCallback,
                      progressCallback: ProgressCallback?,
                      errorCallback: ErrorCallback?) throws {
        guard !files.isEmpty else {
            callback([:])
            return
        }
        
        let db = AirmanDatabase()
        let urls = files.map { url(for: $0) }
        let total = try urls.reduce(0) { try $0 + countLines(in: $1) }
        var count: Int64 = 0
        let progressMutex = DispatchSemaphore(value: 1)
        let group = DispatchGroup()
        
        for file in files {
            do {
                group.enter()
                let rowParserType = Self.rowParser[file]!
                let rowParser = rowParserType.init()
                
                try self.parse(url: self.url(for: file), parseCallback: {
                    try rowParser.parse(parser: $0)
                }, progressCallback: { _ in
                    progressMutex.wait()
                    count += 1
                    if let progressCallback = progressCallback {
                        progressCallback(.init(count, of: total))
                    }
                    progressMutex.signal()
                }, errorCallback: errorCallback, resultCallback: {
                    db.append(airmen: $0)
                    group.leave()
                })
            } catch {
                if let errorCallback = errorCallback { errorCallback(error) }
            }
        }
        
        queue.async {
            group.wait()
            db.merged { callback($0) }
        }
    }
    
    private func parse(url: URL,
                       parseCallback: @escaping ParseCallback,
                       progressCallback: ProgressCallback?,
                       errorCallback: ErrorCallback?,
                       resultCallback: @escaping ParseResultCallback) throws {
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        let total = try countLines(in: url)
        
        queue.async {
            var count: Int64 = 0
            var airmen = Array<Airman>()
            
            while true {
                do {
                    guard let airman = try parseCallback(parser) else { break }
                    airmen.append(airman)
                    count += 1
                    if let progressCallback = progressCallback {
                        progressCallback(.init(count, of: total))
                    }
                } catch {
                    if let errorCallback = errorCallback { errorCallback(error) }
                }
            }
            resultCallback(airmen)
        }
    }
}


