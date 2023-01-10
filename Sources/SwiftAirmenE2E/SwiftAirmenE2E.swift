import Foundation
import ArgumentParser
import Progress

@available(macOS 13.0, *)
@main
struct SwiftAirmenE2E: AsyncParsableCommand {
    @Option(name: .long,
            help: "The directory where data will be downloaded and unzipped.",
            completion: .directory,
            transform: { URL(filePath: $0) })
    var workingDirectory = Process().currentDirectoryURL!
    
    func run() async throws {
        ProgressBar.defaultConfiguration = [
            ProgressPercent(decimalPlaces: 0),
            ProgressBarLine(),
            ProgressTimeEstimates()
        ]
        
        try await AsyncRunner().run()
//        try CombineRunner().run()
//        try CallbacksRunner().run()
    }
}
