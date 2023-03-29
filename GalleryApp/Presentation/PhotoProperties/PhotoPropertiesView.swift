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
        view.layer.shadowColor = UIColor.systemGray2.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        return view
    }()
    
    public let photoFileType = {
        let view = UILabel(frame: .zero)
        view.text = "File type"
        return view
    }()
    
    public let photoSizeLabel = {
        let view = UILabel(frame: .zero)
        view.text = "File size"
        return view
    }()
    
    public let photoDateCreationLabel = {
        let view = UILabel(frame: .zero)
        view.text = "Date"
        return view
    }()
    
    public let photoDateLabel = {
        let view = UILabel(frame: .zero)
        view.text = "Date"
        return view
    }()
    
    public let textView = {
        let view = UITextView()
        view.backgroundColor = .systemGray5
        view.font = .systemFont(ofSize: 18)
        view.layer.cornerRadius = 10
        view.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.layer.borderColor = CGColor(gray: 0.5, alpha: 1.0)
        view.layer.borderWidth = 1.0
        return view
    }()
    
    let stackview = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fillEqually
        view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.isLayoutMarginsRelativeArrangement = true
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
        self.stackview.addArrangedSubview(photoFileType)
        self.stackview.addArrangedSubview(photoSizeLabel)
        self.stackview.addArrangedSubview(photoDateLabel)
        self.stackview.addArrangedSubview(photoDateCreationLabel)
        self.stackview.addArrangedSubview(textView)
    }
    
    func layoutViews() {
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(50)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(400)
        }
        
        stackview.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-50)
            make.width.equalToSuperview().offset(-200)
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp_bottomMargin)
        }
        
        photoFileType.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        photoSizeLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        photoDateLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        photoDateCreationLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        textView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(50)
        }
    }
}
