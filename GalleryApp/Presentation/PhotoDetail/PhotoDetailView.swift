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
    }
    
    func layoutViews() {
        imageSlideShow.snp.makeConstraints { (make) -> Void in
            make.edges.equalToSuperview()
        }
    }
}
