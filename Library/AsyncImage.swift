//
//  AsyncImage.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 17.06.2026.
//

import SwiftUI

/// A SwiftUI view that asynchronously loads and displays a cached remote image.
///
/// Named to avoid colliding with SwiftUI's built-in `AsyncImage`. The
/// `placeholder` is shown while loading and again if loading fails. The load is
/// driven by `.task(id:)`, so it restarts when the URL changes and is cancelled
/// automatically when the view disappears.
public struct AsyncImage<Placeholder: View>: View {
    private let url: URL?
    private let loader: AsyncImageLoader
    private let placeholder: () -> Placeholder

    @State private var phase: Phase = .loading

    private enum Phase {
        case loading
        case success(UIImage)
        case failure
    }

    public init(
        url: URL?,
        loader: AsyncImageLoader = .shared,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.loader = loader
        self.placeholder = placeholder
    }

    public var body: some View {
        content
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .success(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        case .loading, .failure:
            placeholder()
        }
    }

    private func load() async {
        phase = .loading
        guard let url else {
            phase = .failure
            return
        }
        do {
            let image = try await loader.image(from: url)
            phase = .success(image)
        } catch {
            phase = .failure
        }
    }
}
