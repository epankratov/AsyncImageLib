//
//  ImageItem.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 17.06.2026.
//

import Foundation

/// A single entry from the remote image list.
///
/// The demo feed (`picsum.photos`) exposes each item by `id`; the displayable
/// image URL is derived from that id. `id` is decoded leniently so the model
/// works whether the JSON encodes it as a string or a number. For a custom feed
/// shaped as `[{ "id": ..., "url": ... }]`, decode `url` directly here instead.
struct ImageItem: Decodable, Identifiable, Equatable {
    let id: String
    let url: URL

    private enum CodingKeys: String, CodingKey {
        case id
    }

    init(id: String, url: URL) {
        self.id = id
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else {
            id = String(try container.decode(Int.self, forKey: .id))
        }

        guard let imageURL = URL(string: "https://picsum.photos/id/\(id)/400/400") else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Could not build an image URL from id \"\(id)\""
            )
        }
        url = imageURL
    }
}
