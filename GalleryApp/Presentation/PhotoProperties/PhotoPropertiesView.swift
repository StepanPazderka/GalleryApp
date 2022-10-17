//
//  PhotoPropertiesView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation
import UIKit

class PhotoPropertiesView: UIView {
    
    // MARK: - Views
    let imageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    public let photoSizeLabel = {
        let view = UILabel(frame: .zero)
        view.text = "File size"
        return view
    }()
    
    public let photoDateLabel = {
        let view = UILabel(frame: .zero)
        view.text = "Date"
        return view
    }()
    
    let stackview = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fillEqually
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
    
    // MARK: - Setup
    func setupViews() {
        self.addSubview(stackview)
        self.addSubview(imageView)
        self.backgroundColor = .white
        self.stackview.addArrangedSubview(photoSizeLabel)
        self.stackview.addArrangedSubview(photoDateLabel)
    }
    
    func layoutViews() {
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(400)
        }
        
        stackview.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().offset(-20)
//            make.margins.width.equalToSuperview().offset(5)
            make.top.equalTo(imageView.snp_bottomMargin)
            make.leftMargin.equalTo(10)
        }
        
        photoSizeLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        photoDateLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
    }
}
