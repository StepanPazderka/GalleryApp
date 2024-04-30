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
    
	// MARK: Views
    var label: UILabel = {
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
        view.backgroundColor = .tertiarySystemBackground
        return view
    }()
    
	// MARK: Init
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
                         label)
        
        self.focusEffect = .none
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
	
	func setupData(model: SidebarItem) {
		self.label.text = model.title
		self.imageView.image = model.image
		if model.image == nil {
			self.imageView.image = UIImage(named: "rectangle")
		}
		if model.type == .allPhotos {
			self.imageView.contentMode = .scaleAspectFit
		} else {
			self.imageView.contentMode = .scaleAspectFill
		}
	}
    
    func layoutViews() {
        self.imageView.snp.makeConstraints { make in
            make.size.equalTo(30)
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        
        self.label.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(10)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}
