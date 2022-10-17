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
    public let photoSizeLabel = {
        let view = UILabel(frame: .zero)
        view.text = "Test"
        return view
    }()
    
    let stackview = {
        let view = UIStackView()
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
//        self.addSubview(photoSizeLabel)
        self.backgroundColor = .white
        self.stackview.addArrangedSubview(photoSizeLabel)
    }
    
    func layoutViews() {
        stackview.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        
        photoSizeLabel.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.height.equalTo(20)
        }
    }
}
