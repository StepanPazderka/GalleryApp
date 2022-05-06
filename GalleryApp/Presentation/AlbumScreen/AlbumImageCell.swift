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

class AlbumImageCell: UICollectionViewCell {

    var textLabel: UILabel = UILabel()
    var albumImage: UIImageView = UIImageView()
    var delegate: AlbumScreenViewController!
    let checkBox = UICheckBox(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    var index: Int!
    var isEditing: Bool = false {
        didSet {
            checkBox.isHidden = !isEditing
        }
    }
    var isEditingRX: BehaviorRelay = BehaviorRelay<Bool>(value: false)
    var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        checkBox.isHidden = true

        contentView.addSubview(textLabel)
        contentView.addSubview(albumImage)
        contentView.addSubview(checkBox)
        
        checkBox.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
//            make.right.equalToSuperview()
//            make.right.equalTo(albumImage.image)
        }
        
        textLabel.snp.makeConstraints { make in
            make.bottom.equalTo(contentView)
            make.width.equalTo(contentView)
        }
        
        albumImage.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        let navigateToImageRecognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageTapped(_:)))
        navigateToImageRecognizer.numberOfTapsRequired = 1
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        
        let checkImageRecognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageCheckboxTapped(_:)))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(galleryImageLongPress(_:)))
        albumImage.isUserInteractionEnabled = true

        self.isEditingRX.subscribe(onNext: { [weak self] value in
            if value {
//                self?.albumImage.removeGestureRecognizer(navigateToImageRecognizer)
//                self?.albumImage.addGestureRecognizer(checkImageRecognizer)
            } else {
//                self?.albumImage.removeGestureRecognizer(checkImageRecognizer)
//                self?.albumImage.addGestureRecognizer(doubleTap)
//                self?.albumImage.addGestureRecognizer(navigateToImageRecognizer)
            }
        }).disposed(by: disposeBag)
        
        self.albumImage.contentMode = .scaleAspectFit
        self.textLabel.textAlignment = .center
        self.textLabel.text = "ahoj!"
        self.albumImage.backgroundColor = .none
        self.backgroundColor = .none
    }
    
    @objc func doubleTap(_ sender: UITapGestureRecognizer) {
        print("Double tap")
    }
    
    @objc func galleryImageTapped(_ sender: UITapGestureRecognizer) {
        if sender.numberOfTouches == 2 {
            delegate.isEditing = true
            return
        }
        let vc = ContainerBuilder.build().resolve(PhotoDetailViewControllerNew.self, argument: PhotoDetailViewControllerSettings(selectedImages: delegate.listedImages, selectedIndex: self.index))!
        vc.modalPresentationStyle = .none
        delegate.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func galleryImageCheckboxTapped(_ sender: UITapGestureRecognizer) {
        self.checkBox.checker.toggle()
        self.checkBox.isEnabled = false
//        self.checkBox.backgroundColor = .blue
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
