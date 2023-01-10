import Foundation
import Dispatch
import Zip

fileprivate let queue = DispatchQueue(label: "codes.tim.SwiftAirmen.Downloader", attributes: [.concurrent])

extension Downloader {
    /// A callback that yields a downloaded file.
    public typealias FileCallback = (Result<URL, Error>) -> Void
    
    /**
     Downloads and unzips the airmen database to a directory. This directory can
     be used by ``Parser`` to return airmen records.
     
     - Parameter callback: Will be yielded the URL of the downloaded database.
     */
    public func download(callback: @escaping FileCallback) {
        _download(callback: { result in
            guard case let .success(url) = result else {
                callback(result)
                return
            }
            self.unzip(url: url, callback: callback)
        })
    }
    
    private func _download(callback: @escaping FileCallback) {
        let request = URLRequest(url: dataURL())
        let task = session.downloadTask(with: request)
        task.delegate = DownloadDelegate(callback: callback, progressCallback: progressCallback)
        task.resume()
    }
    
    private func unzip(url: URL, to destination: URL? = nil, callback: @escaping FileCallback) {
        queue.async {
            do {
                let folder = destination ?? url.deletingPathExtension()
                let zip = url.deletingPathExtension().appendingPathExtension("zip")
                try FileManager.default.moveItem(at: url, to: zip)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
                try Zip.unzipFile(zip, destination: folder, overwrite: true, password: nil)
                callback(.success(folder))
            } catch {
                callback(.failure(error))
            }
        }
    }
    
    private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        typealias Callback = FileCallback
        
        private let callback: Callback
        private let progressCallback: ProgressCallback?
        
        init(callback: @escaping Callback, progressCallback: ProgressCallback? = nil) {
            self.callback = callback
            self.progressCallback = progressCallback
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            callback(.success(location))
        }
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            guard let error = error else { return }
            callback(.failure(error))
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let error = error else { return }
            callback(.failure(error))
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            guard let progressCallback = progressCallback else { return }
            progressCallback(.init(totalBytesWritten, of: totalBytesExpectedToWrite))
        }
    }
}

