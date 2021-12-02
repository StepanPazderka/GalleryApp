//
//  AlbumImage.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.12.2021.
//

import Foundation
import UIKit

class AlbumImageCell: UICollectionViewCell {
    weak var textLabel: UILabel!
    weak var albumImage: UIImageView!
    var delegate: AllPhotos!
    var index: Int!

    override init(frame: CGRect) {
        super.init(frame: frame)

        let label = UILabel()
        let imageView = UIImageView()

        let checkBox = CheckBox(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        checkBox.backgroundColor = .red
        checkBox.setTitle("Not checked", for: .normal)
        checkBox.isHidden = true

        label.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(label)
        contentView.addSubview(imageView)
        contentView.addSubview(checkBox)

        NSLayoutConstraint.activate([
            checkBox.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        textLabel = label
        albumImage = imageView

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageTapped(_:)))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(galleryImageLongPress(_:)))
        albumImage.isUserInteractionEnabled = true
        albumImage.addGestureRecognizer(tapRecognizer)
//        image.addGestureRecognizer(longPressRecognizer)

        imageView.contentMode = .scaleAspectFit
        textLabel.textAlignment = .center

        //        image.addBlurEffect()
        albumImage.backgroundColor = .none
        self.backgroundColor = .none
    }

    @objc func galleryImageTapped(_ sender: UITapGestureRecognizer) {
        print("Image tapped \(Date())")

        let PhotoDetailScreen = PhotoDetailViewController(nibName: "PhotoDetailViewController", bundle: nil)
        PhotoDetailScreen.modalPresentationStyle = .none
        PhotoDetailScreen.imageSource = self.delegate
        PhotoDetailScreen.selectedIndex = self.index
        delegate.navigationController?.pushViewController(PhotoDetailScreen, animated: true)
    }

    @objc func galleryImageLongPress(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.1, animations: {
            self.albumImage.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
