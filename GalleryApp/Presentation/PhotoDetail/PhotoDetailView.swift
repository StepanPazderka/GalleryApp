//
//  PhotoDetailView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 08.03.2022.
//

import Foundation
import UIKit
import ImageSlideshow

class PhotoDetailView: UIView {
    
    // MARK: -- Views
    let closeButton: UIButton = {
        let view = UIButton(frame: .zero)
        view.setImage(UIImage(systemName: "xmark"), for: .normal)
        return view
    }()
    
    let imageSlideShow: ImageSlideshow = {
        let view = ImageSlideshow()
        view.frame = .zero
        view.zoomEnabled = true
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
        self.addSubview(imageSlideShow)
        self.addSubview(closeButton)
    }
    
    func layoutViews() {
        imageSlideShow.snp.makeConstraints { (make) -> Void in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(30)
        }
    }
}
