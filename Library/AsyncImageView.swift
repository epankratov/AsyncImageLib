//
//  AsyncImageView.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 16.06.2026.
//

import UIKit

/// A `UIView` that asynchronously loads and displays a remote image.
///
/// The placeholder is shown immediately while loading. The view is reuse-safe:
/// starting a new load (or calling `cancelLoading()`) cancels any in-flight
/// request, and a finished download is applied only if its URL still matches the
/// view's current URL — so a recycled cell never shows a stale image.
public class AsyncImageView: UIView {

    // MARK: - Private members
    private let imageView = UIImageView()
    private let placeholder: UIView
    private let loader: AsyncImageLoader

    private var currentURL: URL?
    private var loadTask: Task<Void, Never>?

    public init(loader: AsyncImageLoader = .shared, placeholder: UIView? = nil) {
        self.loader = loader
        self.placeholder = placeholder ?? UIActivityIndicatorView() as UIView
        super.init(frame: .zero)
        setupView()
    }

    public required init?(coder: NSCoder) {
        self.loader = .shared
        self.placeholder = UIActivityIndicatorView()
        super.init(coder: coder)
        setupView()
    }

    deinit {
        loadTask?.cancel()
    }

    /// How the loaded image is scaled within the view's bounds.
    public var imageContentMode: UIView.ContentMode {
        get { imageView.contentMode }
        set { imageView.contentMode = newValue }
    }

    /// Loads `url`, showing `placeholder` until the image is available.
    public func load(url: URL?) {
        cancelLoading()

        // Show placeholder while image is being loaded
        reapplyVisibility(isHidden: true)
        currentURL = url

        guard let url else { return }

        loadTask = Task { [weak self] in
            guard let self else { return }
            let image = try? await self.loader.image(from: url)
            // Ignore the result if the view was reused for a different URL or cancelled.
            guard !Task.isCancelled, self.currentURL == url, let image else { return }

            // Re-display the image view with downloaded content
            reapplyVisibility(isHidden: false)
            self.imageView.image = image
        }
    }

    /// Cancels any in-flight load. Suitable to call from `prepareForReuse`.
    public func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        currentURL = nil
    }
}

// MARK: - Private methods

extension AsyncImageView {

    private func setupView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        placeholder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholder)
        NSLayoutConstraint.activate([
            placeholder.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        (placeholder as? UIActivityIndicatorView)?.startAnimating()
    }

    private func reapplyVisibility(isHidden: Bool) {
        imageView.isHidden = isHidden
        placeholder.isHidden = !isHidden
    }
}
