//
//  CacheKey.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//


import Foundation
import CryptoKit

/// Stable, collision-resistant key derived from an image URL.
///
/// `fileName` is a SHA256 hex digest of the absolute URL string, which makes it
/// safe to use directly as an on-disk file name regardless of the characters in
/// the original URL. The same value is reused as the in-memory cache key.
public nonisolated struct CacheKey: Hashable, Sendable {
    let rawValue: String

    init(url: URL) {
        self.rawValue = url.absoluteString
    }

    /// SHA256 hex digest, safe to use as a file name.
    var fileName: String {
        let digest = SHA256.hash(data: Data(rawValue.utf8))
        let res = digest.map { String(format: "%02x", $0) }.joined()
        return res
    }

    /// Key for `NSCache`, which requires a reference type.
    var memoryKey: NSString {
        fileName as NSString
    }
}
