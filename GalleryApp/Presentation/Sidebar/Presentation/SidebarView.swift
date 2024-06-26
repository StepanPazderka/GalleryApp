//
//  SidebarView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.05.2022.
//

import Foundation
import UIKit
import SnapKit
import RxCocoa

class SidebarView: UIView {
        
    public var sidebarCollectionView: UICollectionView!
    
    let sidebarLayout: UICollectionViewCompositionalLayout = {
        let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = .supplementary
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
        return layout
    }()
    
    var addAlbumButton: UIButton = {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "plus"), for: .normal)
        view.sizeToFit()
        return view
    }()
    
    let selectGalleryButton: UIButton = {
        let view = UIButton()
        view.setTitleColor(UIColor.tintColor, for: .normal)
        view.frame = CGRect(x: 0, y: 0, width: 130, height: 50)
        return view
    }()
    
    init() {
        super.init(frame: .zero)
        
        setupViews()
    }
    
    // MARK: -- Setup Views
    func setupViews() {
        self.sidebarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: sidebarLayout)
        self.addSubviews(sidebarCollectionView)
    }
    
    // MARK: -- Layout Views
    func layoutViews() {
        self.sidebarCollectionView.snp.makeConstraints { (make) -> Void in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
