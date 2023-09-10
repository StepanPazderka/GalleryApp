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
        view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return view
    }()
    
    var checkBoxTapped: UITapGestureRecognizer?
    
    let disposeBag = DisposeBag()
    
    static let identifier: String = String(describing: type(of: AlbumImageCell.self))
    
    // MARK: - Init
    override init(frame: CGRect) {        
        super.init(frame: frame)

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
    
    func configure(with imageData: AlbumImage, viewModel: AlbumScreenViewModel) {
        self.textLabel.text = imageData.title
        self.imageView.image = UIImage(contentsOfFile: imageData.fileName)
        self.viewModel = viewModel
        self.viewModel?.isEditing.subscribe(onNext: { value in
            if value {
                self.checkBox.isHidden = !value
            } else {
                self.checkBox.isHidden = !value
            }
        }).disposed(by: disposeBag)

        bindData()
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
        }
    }
}
