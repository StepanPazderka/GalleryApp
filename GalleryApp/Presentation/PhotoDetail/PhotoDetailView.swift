//
//  PhotoDetailView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 08.03.2022.
//

import Foundation
import UIKit

class PhotoDetailView: UIView {
    
    private var oldBoundsSize: CGSize = .zero
    
    // MARK: - Views
    let closeButton: UIButton = {
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        view.setImage(UIImage(systemName: "xmark"), for: .normal)
        view.frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        return view
    }()

    var swipeDownGestureRecognizer = {
        let view = UIPanGestureRecognizer()
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
        self.addSubviews(closeButton)
    }
    
    func layoutViews() {
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(40)
        }
    }
}
