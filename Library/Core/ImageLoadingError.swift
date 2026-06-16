//
//  ImageLoadingError.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import Foundation

/// Errors surfaced by the image loading library.
nonisolated enum ImageLoadingError: Error, Equatable {
    /// The server responded with a non-success HTTP status code.
    case invalidResponse(statusCode: Int)
    /// The downloaded bytes could not be decoded into an image.
    case decodingFailed
}
