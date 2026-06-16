//
//  AsyncImageCache.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import UIKit

/// Abstraction over the cache used by `ImageLoader`.
///
/// Implementations receive both the decoded `UIImage` and its original encoded
/// `data` on `store`, so each layer can keep whatever representation it needs
/// (a memory layer keeps the decoded image, a disk layer persists the bytes).
public protocol AsyncImageCache: Sendable {
    /// Returns a cached image for the key, or `nil` on a miss or expiry.
    func image(for key: CacheKey) async -> UIImage?

    /// Stores an image and its encoded representation for the key.
    func store(_ image: UIImage, data: Data, for key: CacheKey) async

    /// Removes every cached entry from all layers.
    func removeAll() async
}
