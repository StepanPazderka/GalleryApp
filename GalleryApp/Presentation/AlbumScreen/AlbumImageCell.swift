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
    var isEditing: Bool = false {
        didSet {
            checkBox.isHidden = !isEditing
            if isEditing {
                checkBox.checker = false
            }
        }
    }
    var viewModel: AlbumScreenViewModel?
    var checkBox = {
        let view = UICheckBox(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.isHidden = true
        view.tintColor = .systemGray
        return view
    }()
    var index: Int
    
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
    
    static let identifier: String = String(describing: type(of: AlbumImageCell.self))
    
    // MARK: - Init
    override init(frame: CGRect) {
        self.index = 0
        
        super.init(frame: frame)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(galleryImageLongPress(_:)))
        imageView.isUserInteractionEnabled = true
        
        self.imageView.contentMode = .scaleAspectFit
        self.textLabel.textAlignment = .center
        self.textLabel.text = "ahoj!"
        self.imageView.backgroundColor = .none
        self.backgroundColor = .none
        
        self.setupViews()
        self.layoutViews()
    }
    
    func bindData() {
        self.viewModel?.showingTitles.subscribe(onNext: { value in
            UIView.animate(withDuration: 0.25,
                           animations: {
                if value == false {
                    self.textLabel.alpha = 0
                    self.textLabel.isHidden = true
                } else {
                    self.textLabel.alpha = 1
                    self.textLabel.isHidden = false
                }
            })
        }).disposed(by: disposeBag)
    }
    
    func setupViews() {
        contentView.addSubviews(stackView,
                                checkBox)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectCellRecognizer: UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageCheckboxTapped(_:)))
        recognizer.numberOfTapsRequired = 1
        return recognizer
    }

    @objc func doubleTap(_ sender: UITapGestureRecognizer) {
        print("Double tap")
    }
    
    func configure(with imageData: AlbumImage) {
        self.textLabel.text = imageData.title
        self.imageView.image = UIImage(contentsOfFile: imageData.fileName)
        self.viewModel?.isEditing.subscribe(onNext: { value in
            if value {
//                self.addGestureRecognizer(self.selectCellRecognizer)
                self.checkBox.isHidden = !value
            } else {
//                self.removeGestureRecognizer(self.selectCellRecognizer)
                self.checkBox.isHidden = !value
            }
        }).disposed(by: disposeBag)

        bindData()
    }

    @objc func galleryImageCheckboxTapped(_ sender: UITapGestureRecognizer) {
        if !self.checkBox.checker {
            if let images = self.viewModel?.images {
                self.viewModel?.filesSelectedInEditMode.append(images[self.index].fileName)
            }
        } else {
            if let images = self.viewModel?.images {
                self.viewModel?.filesSelectedInEditMode.removeAll { $0 == images[self.index].fileName } 
            }
        }
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
            make.leadingMargin.equalToSuperview()
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
