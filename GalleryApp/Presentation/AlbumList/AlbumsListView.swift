//
//  AlbumListView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 07.04.2023.
//

import Foundation
import UIKit
import SnapKit

class AlbumsListView: UIView {
    
    var albumsCollectionView: UICollectionView!
    
    var layout: UICollectionViewLayout = {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }()
    
    var selectAlbumButton: UIButton = {
        var view = UIButton()
        view.setTitle(NSLocalizedString("kSELECTALBUM", comment: ""), for: .normal)
        view.tintColor = .systemBlue
        view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        return view
    }()
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
    
    init() {
        super.init(frame: .zero)
        setupViews()
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        albumsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        albumsCollectionView.backgroundColor = .red
        addSubviews(albumsCollectionView)
    }
    
    func layoutViews() {
        albumsCollectionView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
    }
}
