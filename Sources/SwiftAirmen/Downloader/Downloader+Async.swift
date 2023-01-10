import Foundation
import Zip

@available(macOS 13.0, *)
extension Downloader {
    
    /**
     Downloads and unzips the airmen database to a directory. This directory can
     be used by ``Parser`` to return airmen records.
     
     - Returns: The URL of the downloaded airmen database.
     */
    public func download() async throws -> URL {
        let zipfile = try await _download()
        return try await unzip(url: zipfile)
    }
    
    private func _download() async throws -> URL {
        let request = URLRequest(url: dataURL())
        
        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw Errors.networkError(request: request, response: response)
        }
        guard response.statusCode/100 == 2 else {
            throw Errors.networkError(request: request, response: response)
        }
        
        let total = response.expectedContentLength
        var data = Data(capacity: Int(total))
        for try await byte in bytes {
            data.append(byte)
            if let progressCallback = progressCallback {
                progressCallback(.init(Int64(data.count), of: total))
            }
        }
        
        try data.write(to: zipfileLocation())
        return zipfileLocation()
    }
    
    private func unzip(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try Zip.unzipFile(url, destination: folderLocation(), overwrite: true, password: nil)
                continuation.resume(with: .success(folderLocation()))
            } catch {
                continuation.resume(with: .failure(error))
            }
        }
    }
}


