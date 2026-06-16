//
//  AsyncImageCacheManager.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import UIKit

/// Two-tier cache composing a fast in-memory layer over a persistent disk layer.
nonisolated struct AsyncImageCacheManager: AsyncImageCache {
    private let memory: MemoryImageCache
    private let disk: DiskImageCache

    init(
        memory: MemoryImageCache = MemoryImageCache(),
        disk: DiskImageCache = DiskImageCache()
    ) {
        self.memory = memory
        self.disk = disk
    }

    /// Trying to lookup the memory cache first, only then refer the disk cache
    func image(for key: CacheKey) async -> UIImage? {
        if let image = memory.image(for: key) {
            return image
        }
        if let image = await disk.image(for: key) {
            memory.store(image, for: key)
            return image
        }
        return nil
    }

    func store(_ image: UIImage, data: Data, for key: CacheKey) async {
        memory.store(image, for: key)
        await disk.store(data, for: key)
    }

    func removeAll() async {
        memory.removeAll()
        await disk.removeAll()
    }
}
