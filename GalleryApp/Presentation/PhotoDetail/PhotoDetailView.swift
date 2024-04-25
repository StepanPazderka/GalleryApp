//
//  PhotoDetailView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 08.03.2022.
//

import Foundation
import UIKit

class PhotoDetailView: UIView {
        
    // MARK: - Views
    let closeButton: UIButton = {
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.setImage(UIImage(systemName: "xmark"), for: .normal)
        view.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        return view
    }()
    
    let collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
		layout.estimatedItemSize = .zero
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.isPagingEnabled = true
        return view
    }()
    
    var swipeDownGestureRecognizer = {
        let view = UIPanGestureRecognizer()
        return view
    }()
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        
        setupViews()
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Views
    func setupViews() {
        self.addSubviews(closeButton, collectionView)
		self.collectionView.showsHorizontalScrollIndicator = false
    }
    
    func layoutViews() {
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(10)
            make.size.equalTo(40)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
