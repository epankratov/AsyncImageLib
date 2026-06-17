//
//  ImagesListViewModel.swift
//  DemoSwiftUI
//
//  Created by Eugene Pankratov on 17.06.2026.
//

import Foundation
import Combine

/// Drives `ImagesListView`: fetches the image list and exposes view state.
@MainActor
final class ImagesListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([ImageItem])
        case empty
        case failed(String)
    }

    @Published private(set) var state: State = .loading

    /// Changes whenever the cache is invalidated, forcing visible images to reload.
    @Published private(set) var reloadToken = UUID()

    private let service: ImageListProviding
    private let loader: AsyncImageLoader

    init(service: ImageListProviding = ImageListService(), loader: AsyncImageLoader = .shared) {
        self.service = service
        self.loader = loader
    }

    func load() async {
        state = .loading
        do {
            let items = try await service.fetchImageList()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Clears the image cache, then forces visible rows to request their images again.
    func invalidateCache() async {
        await loader.clearCache()
        reloadToken = UUID()
    }
}
