//
//  ViewController.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 15.06.2026.
//

import UIKit

/// Shows the remote image list in a grid. Each cell displays the image (with a
/// placeholder while loading) and its id. A "Clear Cache" bar button invalidates
/// the image cache and reloads the visible images.
final class MainViewController: UIViewController {

    private enum ViewState {
        case loading
        case content
        case empty
        case failed(String)
    }

    private let service: ImageListProviding
    private let loader: AsyncImageLoader
    private var items: [ImageItem] = []

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: Self.makeLayout()
    )
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    init(service: ImageListProviding = ImageListService(), loader: AsyncImageLoader = .shared) {
        self.service = service
        self.loader = loader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.service = ImageListService()
        self.loader = .shared
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Images"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupCollectionView()
        setupOverlays()

        Task { await load() }
    }

    // MARK: - Actions

    @objc private func clearCacheTapped() {
        Task {
            await loader.clearCache()
            // Force visible cells to request their images again.
            collectionView.reloadData()
        }
    }

    @objc private func refreshTriggered() {
        Task { await load() }
    }

    // MARK: - Loading

    private func load() async {
        if items.isEmpty {
            apply(.loading)
        }
        do {
            let fetched = try await service.fetchImageList()
            items = fetched
            collectionView.reloadData()
            apply(fetched.isEmpty ? .empty : .content)
        } catch {
            if items.isEmpty {
                apply(.failed(error.localizedDescription))
            }
        }
        refreshControl.endRefreshing()
    }

    private func apply(_ state: ViewState) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            messageLabel.isHidden = true
            collectionView.isHidden = true
        case .content:
            activityIndicator.stopAnimating()
            messageLabel.isHidden = true
            collectionView.isHidden = false
        case .empty:
            activityIndicator.stopAnimating()
            messageLabel.text = "No images to show."
            messageLabel.isHidden = false
            collectionView.isHidden = true
        case .failed(let message):
            activityIndicator.stopAnimating()
            messageLabel.text = "Couldn't load images.\n\(message)\n\nPull to retry."
            messageLabel.isHidden = false
            collectionView.isHidden = true
        }
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear Cache",
            style: .plain,
            target: self,
            action: #selector(clearCacheTapped)
        )
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        refreshControl.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupOverlays() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .secondaryLabel
        messageLabel.isHidden = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        view.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalWidth(0.62)
            ),
            subitem: item,
            count: 2
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDataSource

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageCell.reuseIdentifier,
            for: indexPath
        )
        if let imageCell = cell as? ImageCell {
            imageCell.configure(with: items[indexPath.item])
        }
        return cell
    }
}
