//
//  SidebarCell.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 21.09.2023.
//

import Foundation
import UIKit
import SnapKit

class SidebarViewCell: UICollectionViewCell {
    static let identifier: String = String(describing: SidebarViewCell.self)
    
    var textView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        return view
    }()
    
    var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    var myBackgroundView: UIView = {
        var view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.selectedBackgroundView = myBackgroundView
        self.setupViews()
        self.layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.addSubviews(imageView, 
                         textView)
        
        self.focusEffect = .none
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
    
    func layoutViews() {
        self.imageView.snp.makeConstraints { make in
            make.size.equalTo(30)
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        
        self.textView.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(10)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}
