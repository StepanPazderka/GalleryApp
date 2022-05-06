//
//  AlbumScreenView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 03.02.2022.
//

import Foundation
import UIKit
import SnapKit

class AlbumScreenView: UIView {
    
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
    
    lazy private var collectionLayout = UICollectionViewFlowLayout()
    
    private var collectionViewLayout2: UICollectionViewFlowLayout {
        let view = UICollectionViewFlowLayout()
        view.itemSize = CGSize(width: self.frame.size.width / 3.3, height: self.frame.size.height / 3.3)
        view.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return view
    }
    
    let doneButton: UIButton = { let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        return button
    }()
    
    let editButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setTitle("Edit", for: .normal)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
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
//        button.setTitle("Add", for: .normal)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.sizeToFit()
        return button
    }()
    
    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.sizeToFit()
        return button
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
        self.backgroundColor = .red
        self.collectionView.collectionViewLayout = collectionLayout
        self.rightStackView.addArrangedSubview(searchButton)
        self.rightStackView.addArrangedSubview(addImageButton)
    }
    
    private func addSubviews() {
        self.addSubview(collectionView)
    }
    
    private func layoutViews() {
        collectionView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
    }
}
