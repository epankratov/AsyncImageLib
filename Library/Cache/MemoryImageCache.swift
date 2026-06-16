//
//  MemoryImageCache.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import UIKit

/// In-memory image cache backed by `NSCache`.
///
/// `NSCache` is thread-safe, so this type is safe to use from any concurrency context.
nonisolated final class MemoryImageCache: @unchecked Sendable {
    private let cache = NSCache<NSString, UIImage>()

    init(countLimit: Int = 0) {
        cache.countLimit = countLimit
    }

    func image(for key: CacheKey) -> UIImage? {
        cache.object(forKey: key.memoryKey)
    }

    func store(_ image: UIImage, for key: CacheKey) {
        cache.setObject(image, forKey: key.memoryKey)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
