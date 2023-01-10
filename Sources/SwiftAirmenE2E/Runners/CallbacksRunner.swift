import Foundation
import Dispatch
import SwiftAirmen

class CallbacksRunner: Runner {
    func run() throws {
        let group = DispatchGroup()
        group.enter()
        
        print("Downloading…")
        try download { result in
            switch result {
                case let .success(url):
                    print("Parsing…")
                    try! self.parse(folder: url) { airmen in
                        self.testResult(airmen: airmen)
                        group.leave()
                    }
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
    
    private func parse(folder: URL, callback: @escaping Parser.ResultCallback) throws {
        let bar = DebouncedProgress()
        bar.start()
        
        let parser = Parser(directory: folder)
        try parser.parse(callback: {
            bar.stop()
            callback($0)
        }, progressCallback: {
            bar.progress = $0
        }, errorCallback: {
            print($0.localizedDescription)
        })
    }
}
