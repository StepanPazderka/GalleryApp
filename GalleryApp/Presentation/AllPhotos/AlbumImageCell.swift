//
//  AlbumImage.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.12.2021.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class AlbumImageCell: UICollectionViewCell, UIContextMenuInteractionDelegate {

    weak var textLabel: UILabel!
    weak var albumImage: UIImageView!
    var delegate: AlbumScreen!
    let checkBox = CheckBox(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    var index: Int!
    var isEditing: Bool = false {
        didSet {
            checkBox.isHidden = !isEditing
        }
    }
    var isEditingRX: BehaviorRelay = BehaviorRelay<Bool>(value: false)
    var disposeBag = DisposeBag()

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                     image: UIImage(systemName: "arrow.up.square")) { action in
                //                self.performInspect()
            }

            let duplicateAction =
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                //                self.performDuplicate()
            }

            let deleteAction =
            UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                //                self.performDelete()
            }

            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let label = UILabel()
        let imageView = UIImageView()


        checkBox.backgroundColor = .red
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

        let navigateToImageRecognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageTapped(_:)))
        let checkImageRecognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageCheckboxTapped(_:)))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(galleryImageLongPress(_:)))
        albumImage.isUserInteractionEnabled = true
        let interaction = UIContextMenuInteraction(delegate: self)
//        albumImage.addInteraction(interaction)

        self.isEditingRX.subscribe(onNext: { [weak self] value in
            if value {
                self?.albumImage.removeGestureRecognizer(navigateToImageRecognizer)
                self?.albumImage.addGestureRecognizer(checkImageRecognizer)
            } else {
                self?.albumImage.removeGestureRecognizer(checkImageRecognizer)
                self?.albumImage.addGestureRecognizer(navigateToImageRecognizer)
            }
        }).disposed(by: disposeBag)
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

    @objc func galleryImageCheckboxTapped(_ sender: UITapGestureRecognizer) {

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
