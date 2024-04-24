//
//  PhotoDetailCollectionViewCell.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.09.2023.
//

import Foundation
import UIKit
import SnapKit

class PhotoDetailCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let identifier = "PhotoDetailCollectionViewCell"
    var imageView = {
        let imageView = PanZoomImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure
    func configure(image: GalleryImage) {
        self.imageView.image = UIImage(contentsOfFile: image.fileName)
        self.imageView.zoomScale = 1.0
    }
    
    func setupViews() {
        self.addSubviews(imageView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageView.zoomScale = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
    }
}
