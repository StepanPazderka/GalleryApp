//
//  PhotoDetailView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 08.03.2022.
//

import Foundation
import UIKit

class PhotoDetailView: UIView {

    // MARK: - Views
    let closeButton: UIButton = {        
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.setImage(UIImage(systemName: "xmark"), for: .normal)
        view.frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        return view
    }()
    
    let imageView: UIImageView = {
        let view = UIImageView(frame: .infinite)
        view.contentMode = .scaleAspectFit
        return view
    }()
        
    // MARK: -- Init
    init() {
        super.init(frame: .zero)
        
        setupViews()
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -- Setup Views
    func setupViews() {
        self.addSubviews(imageView, closeButton)
    }
    
    func layoutViews() {
        imageView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(40)
        }
    }
}
