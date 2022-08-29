//
//  SidebarView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 02.05.2022.
//

import Foundation
import UIKit
import SnapKit

class SidebarView: UIView {
    
    public var collectionView: UICollectionView!
    
    var addAlbumButton: UIBarButtonItem {
        let view = UIButton(type: .system)
        view.setImage(UIImage(systemName: "plus"), for: .normal)
        view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        return UIBarButtonItem(customView: view)
    }
    
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
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.createLayout())
    }
    
    // MARK: -- Layout Views
    func layoutViews() {
        self.collectionView.snp.makeConstraints { (make) -> Void in
            make.edges.equalToSuperview()
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
