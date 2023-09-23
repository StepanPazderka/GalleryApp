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
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
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

    let checkBoxTitles = {
        let view = UICheckBoxButton(frame: CGRect(x: 0, y: 0, width: 80, height: 35))
        view.setTitle("Show titles", for: .normal)
        view.setTitleColor(UIColor.systemBlue, for: .normal)
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
                                                searchButton,
                                                addImageButton,
                                                deleteImageButton)
        self.checkBoxTitles.tintColor = .white
        
        self.checkBoxTitles.checkBoxImageView.layer.shadowColor = UIColor.black.cgColor
        self.checkBoxTitles.checkBoxImageView.layer.shadowOpacity = 1
        self.checkBoxTitles.checkBoxImageView.layer.shadowOffset = .zero
        self.checkBoxTitles.checkBoxImageView.layer.shadowRadius = 15
        
        collectionLayout.itemSize = CGSize(width: 200, height: 200)
    }
    
    private func addSubviews() {
        self.addSubviews(collectionView,
                         bottomToolbarStackView,
                         loadingView)
        
        loadingView.addSubview(progressView)
        
        bottomToolbarStackView.addSubviews(slider,
                                           checkBoxTitles)
    }
    
    private func layoutViews() {
        collectionView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomToolbarStackView.snp.top)
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
        bottomToolbarStackView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(100)
            make.width.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(checkBoxTitles.snp.left).offset(-10).priority(.low)
            make.width.lessThanOrEqualTo(400).priority(.required)
            make.centerY.equalToSuperview()
        }
        checkBoxTitles.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
            make.width.equalTo(130)
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
