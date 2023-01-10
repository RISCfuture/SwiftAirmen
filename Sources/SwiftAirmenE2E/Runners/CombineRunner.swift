import Foundation
import Combine
import Dispatch
import SwiftAirmen

class CombineRunner: Runner {
    private var cancellables = Array<AnyCancellable>()
    
    deinit {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    func run() throws {
        let group = DispatchGroup()
        group.enter()
        
        print("Downloading…")
        try download { result in
            switch result {
                case let .success(url):
                    print("Parsing…")
                    let airmen = try! self.parse(folder: url)
                    airmen.sink(receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            fatalError("Parse failed: \(error.localizedDescription)")
                        }
                    }, receiveValue: { airmen in
                        self.testResult(airmen: airmen)
                        group.leave()
                    }).store(in: &self.cancellables)
                case let .failure(error):
                    fatalError("Download failed: \(error.localizedDescription)")
            }
        }
        
        group.wait()
    }
    
    private func download(callback: @escaping Downloader.FileCallback) throws {
        let bar = DebouncedProgress()
        bar.start()
        
        let downloader = try Downloader() { bar.progress = $0 }
        downloader.download(callback: {
            bar.stop()
            callback($0)
        })
    }
    
    private func parse(folder: URL) throws -> AnyPublisher<Parser.AirmanDictionary, Error> {
        let bar = DebouncedProgress()
        bar.start()
        
        let parser = Parser(directory: folder)
        let (airmen, progress, errors) = try parser.parse()
        
        airmen.sink(receiveCompletion: { _ in bar.stop() }, receiveValue: { _ in })
            .store(in: &cancellables)
        progress.sink { bar.progress = $0 }
            .store(in: &cancellables)
        errors.sink { print($0.localizedDescription) }
            .store(in: &cancellables)
        
        return airmen
    }
}
