import Foundation
import Dispatch
import Progress
import SwiftAirmen

class DebouncedProgress {
    private var progressBar: ProgressBar? = nil
    var progress: SwiftAirmen.Progress?
    
    private static let queue = DispatchQueue(label: "codes.tim.SwiftAirmen.DebouncedProgress", qos: .userInteractive)
    private var timer: DispatchSourceTimer? = nil
    
    func start() {
        timer = DispatchSource.makeTimerSource(queue: Self.queue)
        timer!.setEventHandler { [weak self] in
            guard let self = self else { return }
            guard let progress = self.progress else { return }
            
            if self.progressBar == nil || self.progressBar!.count != progress.total {
                self.progressBar = .init(count: Int(progress.total))
            }
            
            self.progressBar!.setValue(Int(progress.completed))
            
            if progress.isFinished { self.timer?.cancel() }
        }
        
        timer!.schedule(deadline: .now(), repeating: 1.0, leeway: .seconds(1))
        timer!.resume()
    }
    
    func stop() {
        if var progressBar = progressBar {
            progressBar.setValue(progressBar.count)
        }
        timer?.cancel()
    }
}
