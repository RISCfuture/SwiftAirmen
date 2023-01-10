import Foundation
import Combine
import CSV

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Parser {
    typealias AirmanPublisher = AnyPublisher<Airman, Error>
    typealias AirmanArrayPublisher = AnyPublisher<Array<Airman>, Error>
    
    /**
     A publisher that publishes a running progress of the parse task.
     */
    public typealias ProgressPublisher = AnyPublisher<Progress, Never>
    
    /// A publisher that publishes the completed airman database.
    public typealias AirmenPublisher = AnyPublisher<AirmanDictionary, Error>
    
    /// A publisher that publishes any errors that occur during parsing.
    public typealias ErrorPublisher = AnyPublisher<Error, Never>
    
    /**
     The publishers returned from ``parse(files:)``.
     
     - Parameter airmen: A publisher that publishes the completed
     ``AirmanDictionary`` once all airmen have been parsed.
     - Parameter progress: An object that will be updated with the progress of
     the parse operation.
     - Parameter errors: A publisher that publishes parsing errors that occur.
     */
    public typealias Publishers = (airmen: AirmenPublisher, progress: ProgressPublisher, errors: ErrorPublisher)
    
    /**
     Parses all airman records in one or more CSV files. Parsing executes
     asynchronously. Errors do not stop parsing; they are given back to you via
     a different publisher, and the row is skipped.
     
     - Parameter files: The files to parse. This array should be unique,
     otherwise parsing will be unnecessarily slower.
     - Returns: Airmen, progress, and error publishers.
     */
    public func parse(files: Array<File> = File.allCases) throws -> Publishers {
        guard !files.isEmpty else {
            return (
                Empty(completeImmediately: true).eraseToAnyPublisher(),
                Empty(completeImmediately: true).eraseToAnyPublisher(),
                Empty(completeImmediately: true).eraseToAnyPublisher()
            )
        }
        
        let urls = files.map { url(for: $0) }
        let total = try urls.reduce(0) { try $0 + countLines(in: $1) }
        
        var airmenPublishers = Array<AirmanArrayPublisher>()
        var progressPublishers = Array<ProgressPublisher>()
        var errorPublishers = Array<ErrorPublisher>()
        
        for file in files {
            let url = url(for: file)
            let rowParserType = Self.rowParser[file]!
            let rowParser = rowParserType.init()
            
            let (pub, progressPub, errorPub) = try self.parse(url: url, parseCallback: {
                try rowParser.parse(parser: $0)
            })
            
            airmenPublishers.append(pub.collect().eraseToAnyPublisher())
            progressPublishers.append(progressPub)
            errorPublishers.append(errorPub)
        }
        
        let mergedPub: AirmanArrayPublisher
        let mergedProgressPub: ProgressPublisher
        let mergedErrorPub: ErrorPublisher
        switch files.count {
            case 1:
                mergedPub = airmenPublishers[0]
                mergedProgressPub = progressPublishers[0]
                mergedErrorPub = errorPublishers[0]
            case 2:
                mergedPub = airmenPublishers[0]
                    .merge(with: airmenPublishers[1])
                    .eraseToAnyPublisher()
                mergedProgressPub = progressPublishers[0]
                    .merge(with: progressPublishers[1])
                    .eraseToAnyPublisher()
                mergedErrorPub = errorPublishers[0]
                    .merge(with: errorPublishers[1])
                    .eraseToAnyPublisher()
            case 3:
                mergedPub = airmenPublishers[0]
                    .merge(with: airmenPublishers[1], airmenPublishers[2])
                    .eraseToAnyPublisher()
                mergedProgressPub = progressPublishers[0]
                    .merge(with: progressPublishers[1], progressPublishers[2])
                    .eraseToAnyPublisher()
                mergedErrorPub = errorPublishers[0]
                    .merge(with: errorPublishers[1], errorPublishers[2])
                    .eraseToAnyPublisher()
            case 4:
                mergedPub = airmenPublishers[0]
                    .merge(with: airmenPublishers[1], airmenPublishers[2], airmenPublishers[3])
                    .eraseToAnyPublisher()
                mergedProgressPub = progressPublishers[0]
                    .merge(with: progressPublishers[1], progressPublishers[2], progressPublishers[3])
                    .eraseToAnyPublisher()
                mergedErrorPub = errorPublishers[0]
                    .merge(with: errorPublishers[1], errorPublishers[2], errorPublishers[3])
                    .eraseToAnyPublisher()
            default:
                fatalError("Up to four CSV file types can be specified")
        }
        
        let combinedPub = mergedPub
            .reduce(AirmanDatabase()) { $0.append(airmen: $1) }
            .map { $0.merged() }
            .eraseToAnyPublisher()
        let combinedProgressPub = mergedProgressPub
            .scan(Int64(0)) { sum, _ in sum + 1 }
            .map { Progress($0, of: total) }
            .eraseToAnyPublisher()
        
        return (airmen: combinedPub, progress: combinedProgressPub, errors: mergedErrorPub)
    }
    
    private func parse(url: URL, parseCallback: @escaping ParseCallback) throws -> (AirmanPublisher, ProgressPublisher, ErrorPublisher) {
        let subject = PassthroughSubject<Airman, Error>()
        let progressSubject = PassthroughSubject<Progress, Never>()
        let errorSubject = PassthroughSubject<Error, Never>()
        
        let parser = try CSVParser(url: url, delimiter: ",", hasHeader: true, header: nil)
        let total = try countLines(in: url)
        
        queue.async {
            var count: Int64 = 0
            while true {
                do {
                    guard let airman = try parseCallback(parser) else { break }
                    subject.send(airman)
                    count += 1
                    progressSubject.send(.init(count, of: total))
                } catch {
                    errorSubject.send(error)
                }
            }
        }
        
        return (
            subject.eraseToAnyPublisher(),
            progressSubject.eraseToAnyPublisher(),
            errorSubject.eraseToAnyPublisher()
        )
    }
}



