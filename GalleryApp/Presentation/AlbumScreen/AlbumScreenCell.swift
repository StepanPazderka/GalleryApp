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

class AlbumScreenCell: UICollectionViewCell {
    
    // MARK: - Properties
    var isEditing = false
	
    weak var viewModel: AlbumScreenViewModel?
	weak var settingsManager: (any SettingsManager)?
    
    var containerViewForCheck: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    var checkmarkView: UIImageView = {
        let image = UIImage(systemName: "checkmark.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .light))
        let imageView = UIImageView()
        imageView.image = image
        imageView.tintColor = .white
        return imageView
    }()
    
    var checkmarkViewFill: UIImageView = {
        let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .light))
        let imageView = UIImageView()
        imageView.image = image
        imageView.tintColor = .systemBlue
        return imageView
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
    
    var isSelectedOverlay = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        view.alpha = 0.5
        return view
    }()
        
	var filename: String?
	var pathResolver: PathResolver?
	
	var galleryImage: GalleryImage?
	
    let disposeBag = DisposeBag()
    
    static let identifier: String = String(describing: type(of: AlbumScreenCell.self))
    
    // MARK: - Init
	override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView.isUserInteractionEnabled = true
        
        self.imageView.contentMode = .scaleAspectFit
        self.textLabel.textAlignment = .center
        self.imageView.backgroundColor = .none
        self.backgroundColor = .none
        
        self.setupViews()
        self.layoutViews()
    }
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    func bindData() {
        self.viewModel?.showingAnnotationsAsObservable().subscribe(onNext: { [weak self] value in
            UIView.animate(withDuration: 0.25,
                           animations: {
                if value == false {
                    self?.textLabel.alpha = 0
					self?.textLabel.isHidden = true
                } else {
                    self?.textLabel.alpha = 1
					self?.textLabel.isHidden = false
                }
            })
        }).disposed(by: disposeBag)
		
		self.viewModel?.getCurrentSelectedGalleryIDAsObservable().subscribe(onNext: { [weak self] (id: String) in
			if let fileName = self?.filename, let pathResolver = self?.pathResolver {
				let resolvedPath = pathResolver.resolveThumbPathFor(imageName: fileName)
				self?.imageView.image = UIImage(contentsOfFile: resolvedPath)
			}
		}).disposed(by: disposeBag)
    }

    func setupViews() {
        containerViewForCheck.addSubviews(checkmarkViewFill, checkmarkView)
        
        contentView.addSubviews(stackView,
                                isSelectedOverlay,
                                containerViewForCheck)
        
        stackView.addArrangedSubviews(imageView, textLabel)
    }
    
	func setup(with galleryImage: GalleryImage, viewModel: AlbumScreenViewModel, pathResolver: PathResolver) {
        self.textLabel.text = galleryImage.title
		self.filename = galleryImage.fileName
		self.galleryImage = galleryImage
		self.pathResolver = pathResolver
		let resolvedThumbnailPath = pathResolver.resolveThumbPathFor(imageName: galleryImage.fileName)
		self.imageView.image = UIImage(contentsOfFile: resolvedThumbnailPath)
        self.viewModel = viewModel
        self.isSelected = false
        
        bindData()
    }
    
    func layoutViews() {
        checkmarkView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        checkmarkViewFill.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerViewForCheck.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.right.equalTo(imageView.contentClippingRect.width)
            make.bottom.equalTo(imageView.contentClippingRect.height)
        }
        
        isSelectedOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        textLabel.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        stackView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
    }
    
    func showSelectedView() {
        self.containerViewForCheck.isHidden = false
        self.isSelectedOverlay.isHidden = false
    }
    
    func hideSelectedView() {
        self.containerViewForCheck.isHidden = true
        self.isSelectedOverlay.isHidden = true
    }
}
