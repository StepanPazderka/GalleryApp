//
//  AlbumScreenView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 03.02.2022.
//

import Foundation
import UIKit
import SnapKit
import UniformTypeIdentifiers
import Photos
import PhotosUI

class AlbumScreenView: UIView {
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
    
    var collectionLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()
    
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.sizeToFit()
        return button
    }()
    
    let leftStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        view.sizeToFit()
        view.spacing = 20
        return view
    }()
    
    let rightStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        view.sizeToFit()
        view.spacing = 20
        return view
    }()
    
    let addImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.sizeToFit()
        return button
    }()
    
    let deleteImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.sizeToFit()
        return button
    }()
    
    let documentPicker: UIDocumentPickerViewController = {
        let allowedTypes: [UTType] = [UTType.image]
        let view = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        return view
    }()
    
    var loadingView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 20
        view.isHidden = true
        return view
    }()
    
    var progressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.trackTintColor = .systemGray
        view.progress = 0.0
        return view
    }()
    
    let imagePicker = {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = 0
        let view = PHPickerViewController(configuration: configuration)
        return view
    }
    
    let bottomToolbarStackView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.frame.size.height = 200
        return view
    }()
    
    let slider: UISlider = {
        let view = UISlider()
        view.minimumValue = 10
        view.maximumValue = 300
        view.value = calculateAverage([view.minimumValue, view.maximumValue])
        return view
    }()
	
	var viewButton = {
		let view = UIButton(primaryAction: nil)
		view.setTitle("View options", for: .normal)
		view.titleLabel?.font = UIFont.systemFont(ofSize: 20)
		view.contentHorizontalAlignment = .center
		view.showsMenuAsPrimaryAction = true
		view.changesSelectionAsPrimaryAction = true
		return view
	}()
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        
        setupViews()
        addSubviews()
        layoutViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.collectionView.collectionViewLayout = collectionLayout
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.dragInteractionEnabled = true
        self.rightStackView.addArrangedSubviews(editButton,
                                                addImageButton,
                                                deleteImageButton)
        
        collectionLayout.itemSize = CGSize(width: 200, height: 200)
    }
    
    private func addSubviews() {
        self.addSubviews(collectionView,
                         bottomToolbarStackView,
                         loadingView,
						 viewButton)
        
        loadingView.addSubview(progressView)
        
        bottomToolbarStackView.addSubviews(slider,
										   viewButton)
    }
    
    private func layoutViews() {
        collectionView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomToolbarStackView.snp.top)
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
        bottomToolbarStackView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(75)
            make.width.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(viewButton.snp.left).offset(-10).priority(.low)
            make.width.lessThanOrEqualTo(400).priority(.required)
            make.centerY.equalToSuperview()
        }
		viewButton.snp.makeConstraints { make in
			make.right.equalToSuperview().offset(-20)
			make.centerY.equalToSuperview()
			make.width.equalTo(120)
		}
        loadingView.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-400)
            make.height.equalTo(200)
            make.center.equalToSuperview()
        }
        progressView.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-200)
            make.height.equalTo(4)
            make.center.equalToSuperview()
        }
    }
}
