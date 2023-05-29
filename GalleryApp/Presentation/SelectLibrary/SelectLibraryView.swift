//
//  SelectLibraryView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.04.2023.
//

import Foundation
import UIKit
import SnapKit

class SelectLibraryView: UIView {
    
    lazy var galleriesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
    
    var collectionLayout: UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.showsSeparators = false
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    
    var rightBarButton: UIButton = {
        var view = UIButton()
        view.setTitle("", for: .normal)
        view.setImage(UIImage(systemName: "plus"), for: .normal)
        view.sizeToFit()
        return view
    }()
    
    var closeButton: UIButton = {
        var view = UIButton()
        view.setTitle("", for: .normal)
        view.setImage(UIImage(systemName: "xmark"), for: .normal)
        view.sizeToFit()
        return view
    }()
        
    init() {
        super.init(frame: .zero)
        
        self.setupViews()
        self.layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.addSubviews(galleriesCollectionView)
    }
    
    func layoutViews() {
        self.galleriesCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}