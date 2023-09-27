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
    let imagesContainer = {
        let view = UIView()
        return view
    }()
    
    let imageView1 = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.shadowColor = UIColor.systemGray2.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        return view
    }()
    
    let imageView2 = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.shadowColor = UIColor.systemGray2.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        let degrees: CGFloat = 45.0
        let radians = degrees * .pi / 46.0
        view.transform = CGAffineTransform(rotationAngle: radians)
        return view
    }()
    
    let imageView3 = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.shadowColor = UIColor.systemGray2.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        let degrees: CGFloat = 45.0
        let radians = degrees * .pi / 47.0
        view.transform = CGAffineTransform(rotationAngle: radians)
        return view
    }()
    
    public let itemFileTypeLabel = {
        let view = UILabel(frame: .zero)
        view.text = "File type"
        return view
    }()
    
    public let itemFileSizeLabel = {
        let view = UILabel(frame: .zero)
        view.text = "File size"
        return view
    }()
    
    public let itemCreationDateLabel = {
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
        view.layoutMargins = UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0)
        view.isLayoutMarginsRelativeArrangement = false
        return view
    }()
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        
        self.setupViews()
        self.layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    func setupViews() {
        self.backgroundColor = .white
        imagesContainer.addSubviews(imageView3,
                                    imageView2,
                                    imageView1)
        self.addSubviews(stackview,
                         imagesContainer)
        self.stackview.addArrangedSubviews(itemFileTypeLabel,
                                           itemFileSizeLabel,
                                           photoDateLabel,
                                           itemCreationDateLabel,
                                           textView)
    }
    
    func layoutViews() {
        imagesContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(50)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(400)
        }
        
        imageView1.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageView2.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageView3.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackview.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-100)
            make.width.equalToSuperview().offset(-200)
            make.centerX.equalToSuperview()
            make.top.equalTo(imagesContainer.snp.bottom).offset(30)
        }
        
        itemFileTypeLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        itemFileSizeLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        photoDateLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        itemCreationDateLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        
        textView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(50)
        }
    }
}
