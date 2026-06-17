//
//  ImagesListView.swift
//  DemoSwiftUI
//
//  Created by Eugene Pankratov on 17.06.2026.
//

import SwiftUI

/// Screen showing the list of images, each with its id, plus a button to
/// invalidate the image cache. Mirrors the UIKit demo, built on the same library.
struct ImagesListView: View {
    @StateObject private var viewModel = ImagesListViewModel()

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Images")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear Cache") {
                            Task { await viewModel.invalidateCache() }
                        }
                    }
                }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let items):
            grid(items)
        case .empty:
            message("No images to show.")
        case .failed(let description):
            failure(description)
        }
    }

    private func grid(_ items: [ImageItem]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    VStack(spacing: 4) {
                        AsyncImage(url: item.url) {
                            ZStack {
                                Color(uiColor: .secondarySystemBackground)
                                ProgressView()
                            }
                        }
                        .id(viewModel.reloadToken) // Reload after cache invalidation.
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("ID: \(item.id)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .refreshable { await viewModel.load() }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failure(_ description: String) -> some View {
        VStack(spacing: 12) {
            Text("Couldn't load images.")
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ImagesListView()
}
