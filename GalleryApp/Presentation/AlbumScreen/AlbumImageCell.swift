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
import ImageViewer

class AlbumImageCell: UICollectionViewCell {

    // MARK: - Properties
    var viewModel: AlbumScreenViewModel?
    var router: AlbumScreenRouter?
    let checkBox = UICheckBox(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    var index: Int
//    var isEditing: Bool = false {
//        didSet {
//            checkBox.isHidden = !isEditing
//        }
//    }
    
    // MARK: - Views
    var textLabel = {
        let view = UILabel()
        return view
    }()
    
    var imageView = UIImageView()
    
    var stackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fillProportionally
        return view
    }()
    
    var checkBoxTapped: UITapGestureRecognizer?
    
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    static let identifier: String = String(describing: type(of: AlbumImageCell.self))
    
    // MARK: - Init
    override init(frame: CGRect) {
        self.index = 0
        
        super.init(frame: frame)
        
        checkBox.isHidden = true
        
        contentView.addSubviews(stackView,
                                checkBox)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textLabel)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(galleryImageLongPress(_:)))
        imageView.isUserInteractionEnabled = true
        
        self.imageView.contentMode = .scaleAspectFit
        self.textLabel.textAlignment = .center
        self.textLabel.text = "ahoj!"
        self.imageView.backgroundColor = .none
        self.backgroundColor = .none

        self.addGestureRecognizer(navigateToImageRecognizer)
        
        self.layoutViews()
    }
    
    func bindData() {
        self.viewModel?.showingTitles.subscribe(onNext: { value in
            UIView.animate(withDuration: 0.25,
                           animations: {
                if value == false {
                    self.textLabel.alpha = 0
                } else {
                    self.textLabel.alpha = 1
                }
            })
        }).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var navigateToImageRecognizer: UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageTapped(_:)))
        recognizer.numberOfTapsRequired = 1
        return recognizer
    }
    
    var checkImageRecognizer: UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageCheckboxTapped(_:)))
        return recognizer
    }

    @objc func doubleTap(_ sender: UITapGestureRecognizer) {
        print("Double tap")
    }
    
    func configure(imageData: AlbumImage) {
        self.textLabel.text = imageData.title
        
        self.viewModel?.isEditing.subscribe(onNext: { value in
            if value {
                self.removeGestureRecognizer(self.navigateToImageRecognizer)
                self.addGestureRecognizer(self.checkImageRecognizer)
            } else {
                self.removeGestureRecognizer(self.checkImageRecognizer)
                self.addGestureRecognizer(self.navigateToImageRecognizer)
            }
        }).disposed(by: disposeBag)
        
        viewModel?.showingTitles.subscribe(onNext: { value in
            UIView.animate(withDuration: 0.25,
                           animations: {
                self.textLabel.isHidden = value
            })
        }).disposed(by: disposeBag)
    }
    
    @objc func galleryImageTapped(_ sender: UITapGestureRecognizer) {
        if let viewModel = viewModel, let router = router {
            if sender.numberOfTouches == 2 {
                viewModel.isEditing.accept(true)
                return
            } else {
                router.showPhotoDetail(images: viewModel.images, index: self.index)
            }
        }
    }

    @objc func galleryImageCheckboxTapped(_ sender: UITapGestureRecognizer) {
        self.checkBox.checker.toggle()
        self.checkBox.isEnabled = false
    }

    @objc func galleryImageLongPress(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.1, animations: {
            self.imageView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        })
    }
    
    func layoutViews() {
        checkBox.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.left.equalToSuperview()
            make.size.equalTo(20)
        }
        
        textLabel.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        stackView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.margins.equalTo(0)
        }
    }
}
