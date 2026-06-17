//
//  ImageCell.swift
//  AsyncImageLib
//
//  Created by Eugene Pankratov on 17.06.2026.
//

import UIKit

/// A grid cell showing a remote image (placeholder while loading) and its id.
final class ImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ImageCell"

    private let asyncImageView = AsyncImageView()
    private let idLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func configure(with item: ImageItem) {
        idLabel.text = "ID: \(item.id)"
        asyncImageView.load(url: item.url)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        asyncImageView.cancelLoading()
        idLabel.text = nil
    }

    private func setupViews() {
        asyncImageView.imageContentMode = .scaleAspectFill
        asyncImageView.backgroundColor = .secondarySystemBackground
        asyncImageView.layer.cornerRadius = 8
        asyncImageView.clipsToBounds = true
        asyncImageView.translatesAutoresizingMaskIntoConstraints = false

        idLabel.font = .preferredFont(forTextStyle: .footnote)
        idLabel.textColor = .secondaryLabel
        idLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(asyncImageView)
        contentView.addSubview(idLabel)

        NSLayoutConstraint.activate([
            asyncImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            asyncImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            asyncImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            idLabel.topAnchor.constraint(equalTo: asyncImageView.bottomAnchor, constant: 4),
            idLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            idLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            idLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
