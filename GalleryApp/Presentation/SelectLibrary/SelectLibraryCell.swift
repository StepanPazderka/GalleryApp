//
//  GalleryCell.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.04.2023.
//

import Foundation
import UIKit
import SnapKit

class SelectLibraryCell: UICollectionViewCell {
    var text: UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        return view
    }()
    
    var customSelectedBackgroundView: UIView {
        let inset = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        
        let view = UIView(frame: bounds.inset(by: inset))
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 10
        return view
    }
    
    static let identifier = "GalleryCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.selectedBackgroundView = customSelectedBackgroundView
        self.setupViews()
        self.layoutViews()
    }
    
    func setupViews() {
        contentView.addSubviews(text)
    }
    
    func layoutViews() {
        self.text.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.size.width.equalToSuperview()
            make.size.height.equalTo(50)
            make.leftMargin.equalTo(20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
