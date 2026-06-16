//
//  DiskImageCache.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import UIKit

/// Persistent image cache backed by the file system storage.
///
/// Encoded image bytes are written into a dedicated directory inside the
/// system caches directory, so entries survive app restarts. Each entry's age
/// is derived from its file modification date; entries older than
/// `expiration` are treated as a miss and deleted on access.
///
/// File I/O is serialized on the actor's executor, keeping it off the main thread.
actor DiskImageCache {
    private let directory: URL
    private let expiration: TimeInterval
    private let fileManager: FileManager
    private let now: @Sendable () -> Date

    /// - Parameters:
    ///   - directoryName: Sub-directory created inside the caches directory.
    ///   - expiration: Maximum age of a valid entry. Defaults to 4 hours.
    ///   - fileManager: Injectable for testing.
    ///   - now: Injectable clock for testing expiration.
    init(
        directoryName: String = "AsyncImageLib.Cache",
        expiration: TimeInterval = 4 * 60 * 60,
        fileManager: FileManager = .default,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.expiration = expiration
        self.fileManager = fileManager
        self.now = now

        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let base = caches.first ?? fileManager.temporaryDirectory
        self.directory = base.appendingPathComponent(directoryName, isDirectory: true)
    }

    func image(for key: CacheKey) -> UIImage? {
        let url = fileURL(for: key)
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        if now().timeIntervalSince(modificationDate) > expiration {
            try? fileManager.removeItem(at: url)
            return nil
        }

        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    func store(_ data: Data, for key: CacheKey) {
        createDirectoryIfNeeded()
        try? data.write(to: fileURL(for: key), options: .atomic)
    }

    func removeAll() {
        try? fileManager.removeItem(at: directory)
    }

    private func fileURL(for key: CacheKey) -> URL {
        directory.appendingPathComponent(key.fileName, isDirectory: false)
    }

    private func createDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: directory.path) else { return }
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
