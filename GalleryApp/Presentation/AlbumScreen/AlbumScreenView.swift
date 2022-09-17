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

class AlbumScreenView: UIView {
    
    let toolbarHeight = 100
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
    
    lazy var collectionLayout = UICollectionViewFlowLayout()
    
    var collectionViewLayout2: UICollectionViewFlowLayout {
        let view = UICollectionViewFlowLayout()
        view.itemSize = CGSize(width: self.frame.size.width / 3, height: self.frame.size.height / 3)
        view.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return view
    }
    
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.sizeToFit()
        return button
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
    
    let slider: UISlider = {
        let view = UISlider()
        view.minimumValue = 10
        view.maximumValue = 300
        view.value = calculateAverage([view.minimumValue, view.maximumValue])
        return view
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
    
    let imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.allowsEditing = false
        return view
    }()
    
    let bottomToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.frame.size.height = 200
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
        self.rightStackView.addArrangedSubview(editButton)
        self.rightStackView.addArrangedSubview(searchButton)
        self.rightStackView.addArrangedSubview(addImageButton)
        
        collectionLayout.itemSize = CGSize(width: 200, height: 200)
    }
    
    private func addSubviews() {
        self.addSubview(collectionView)
        self.addSubview(bottomToolbar)
        bottomToolbar.addSubview(slider)
    }
    
    private func layoutViews() {
        collectionView.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(bottomToolbar.snp.top)
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
        bottomToolbar.snp.makeConstraints { make in
            make.bottom.equalTo(self)
            make.height.equalTo(toolbarHeight)
            make.width.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalTo(300)
        }
    }
}
