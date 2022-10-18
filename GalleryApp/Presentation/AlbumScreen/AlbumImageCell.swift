//
//  AlbumImageCell.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.12.2021.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class AlbumImageCell: UICollectionViewCell {

    var router: AlbumScreenRouter?
    var textLabel: UILabel = UILabel()
    var imageView: UIImageView = UIImageView()
    var delegate: AlbumScreenViewController?
    let checkBox = UICheckBox(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    var index: Int
    var isEditing: Bool = false {
        didSet {
            checkBox.isHidden = !isEditing
        }
    }
    
    var navigateToImageRecognizer: UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageTapped(_:)))
        recognizer.numberOfTapsRequired = 1
        return recognizer
    }
    let checkImageRecognizer = UITapGestureRecognizer(target: AlbumImageCell.self, action: #selector(galleryImageCheckboxTapped(_:)))
    var checkBoxTapped: UITapGestureRecognizer?
    let disposeBag = DisposeBag()
    static let identifier: String = String(describing: type(of: AlbumImageCell.self))
    
    override init(frame: CGRect) {
        self.index = 0
        
        super.init(frame: frame)
        
        checkBox.isHidden = true

        contentView.addSubview(textLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(checkBox)
        
        checkBox.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        textLabel.snp.makeConstraints { make in
            make.bottom.equalTo(contentView)
            make.width.equalTo(contentView)
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        
        
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(galleryImageLongPress(_:)))
        imageView.isUserInteractionEnabled = true
        
        self.imageView.contentMode = .scaleAspectFit
        self.textLabel.textAlignment = .center
//        self.textLabel.text = "ahoj!"
        self.imageView.backgroundColor = .none
        self.backgroundColor = .none

        self.addGestureRecognizer(navigateToImageRecognizer)
    }
    
    @objc func doubleTap(_ sender: UITapGestureRecognizer) {
        print("Double tap")
    }
    
    func configure(imageData: AlbumImage) {
        self.delegate?.editingRx.subscribe(onNext: { value in
            if value {
                self.removeGestureRecognizer(self.navigateToImageRecognizer)
                self.addGestureRecognizer(self.checkImageRecognizer)
            } else {
                self.addGestureRecognizer(self.navigateToImageRecognizer)
                self.navigateToImageRecognizer.isEnabled = true
            }
        }).disposed(by: disposeBag)
    }
    
    @objc func galleryImageTapped(_ sender: UITapGestureRecognizer) {
        if let delegate = delegate {
            if sender.numberOfTouches == 2 {
                delegate.isEditing = true
                return
            }
            delegate.router.showPhotoDetail(images: delegate.viewModel.images, index: self.index)
            
        }
    }

    @objc func galleryImageCheckboxTapped(_ sender: UITapGestureRecognizer) {
        self.checkBox.checker.toggle()
        self.checkBox.isEnabled = false
        self.checkBox.backgroundColor = .blue
//        self.checkBox.backgroundColor = .blue
    }

    @objc func galleryImageLongPress(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.1, animations: {
            self.imageView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
