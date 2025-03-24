import Foundation
import Progress
import SwiftAirmen

actor DebouncedProgress {
    private var progressBar: ProgressBar? = nil
    var progress: SwiftAirmen.Progress?
    private var progressTask: Task<Void, Never>?

    func setProgress(_ progress: SwiftAirmen.Progress) { self.progress = progress }

    private func updateProgressBar() async {
        guard let progress = self.progress else { return }

        let total = await progress.total
        if progressBar == nil || progressBar!.count != total {
            progressBar = await .init(count: Int(progress.total))
        }

        await self.progressBar?.setValue(Int(progress.completed))
    }

    func start() {
        progressTask?.cancel()

        progressTask = Task { [weak self] in
            guard let self else { return }
            do {
                while true {
                    try Task.checkCancellation()

                    await self.updateProgressBar()

                    let isFinished = await progress?.isFinished ?? false
                    if isFinished { break }
                    try await Task.sleep(for: .seconds(1))
                }
            } catch is CancellationError {
                // let task end
            } catch {
                var stderr = StandardError()
                print(error.localizedDescription, to: &stderr)
                // let task end
            }
        }
    }

    func stop() {
        if var progressBar {
            progressBar.setValue(progressBar.count)
        }
        progressTask?.cancel()
        progressTask = nil
    }
}
