//
//  ImageListService.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 17.06.2026.
//

import Foundation

/// Endpoints used by the example app, kept in one place.
nonisolated enum ImageEndpoint {
    /// Remote image list.
    ///
    /// No specific JSON URL was provided with the assignment, so the demo points
    /// at the public `picsum.photos` list API, which returns objects containing
    /// an `id`. Replace this with your own `[{ "id": ..., "url": ... }]` endpoint
    /// (and adjust `ImageItem` decoding) to use a different feed.
    static let imageList = URL(string: "https://picsum.photos/v2/list?page=1&limit=30")
}

/// Loads the list of images to display.
nonisolated protocol ImageListProviding: Sendable {
    func fetchImages() async throws -> [ImageItem]
}

/// Fetches and decodes the image list over the network using `URLSession`.
nonisolated struct ImageListService: ImageListProviding {
    private let endpoint: URL?
    private let session: URLSession

    init(endpoint: URL? = ImageEndpoint.imageList, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func fetchImages() async throws -> [ImageItem] {
        guard let endpoint else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: endpoint)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([ImageItem].self, from: data)
    }
}
