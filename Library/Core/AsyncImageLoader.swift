//
//  AsyncImageLoader.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import UIKit

/// Singleton, it manages loading of images by theirs URLs.
/// This implementation is backed by a two-tier (memory + disk) cache.
///
/// Lookups resolve in order: memory cache, disk cache, then network. Successful
/// downloads populate both cache layers. Concurrent requests for the same URL
/// share a single in-flight task, so an image is never downloaded twice at once.
actor AsyncImageLoader {
    /// Shared instance used by the UI components and the example app.
    static let shared = AsyncImageLoader()

    private let cache: AsyncImageCache
    private let session: URLSession
    /// Tasks being executed
    private var inFlight: [CacheKey: Task<UIImage, Error>] = [:]

    init(cache: AsyncImageCache = AsyncImageCacheManager(), session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    /// Returns the image for `url`, loading and caching it if necessary.
    func image(from url: URL) async throws -> UIImage {
        let key = CacheKey(url: url)

        // Join an existing download for the same URL instead of starting a new one.
        if let existing = inFlight[key] {
            return try await existing.value
        }

        let task = Task<UIImage, Error> { [cache, session] in
            if let cached = await cache.image(for: key) {
                return cached
            }

            let (data, response) = try await session.data(from: url)
            try Self.validate(response)

            guard let image = UIImage(data: data) else {
                throw ImageLoadingError.decodingFailed
            }

            await cache.store(image, data: data, for: key)
            return image
        }

        inFlight[key] = task
        defer { inFlight[key] = nil }
        return try await task.value
    }

    /// Clears both the memory and disk caches.
    func clearCache() async {
        await cache.removeAll()
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw ImageLoadingError.invalidResponse(statusCode: http.statusCode)
        }
    }
}

public func printLog(_ message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    let className = (fileName as NSString).lastPathComponent
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateStr = formatter.string(from: Date())
#if DEBUG
    let prefix = ":[DEBUG]"
#else
    let prefix = ""
#endif
    print("[\(dateStr)]\(prefix) \(className)->\(functionName) {#\(lineNumber)} | \(message)")
}
