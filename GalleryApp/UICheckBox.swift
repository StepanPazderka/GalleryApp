//
//  CheckBox.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 18.01.2021.
//

import UIKit

@MainActor class UICheckBox: UIButton {
    var checker: Bool = false {
        didSet {
            if checker == false {
                image.image = UIImage(systemName: "checkmark.circle")
            } else {
                image.image = UIImage(systemName: "checkmark.circle.fill")
            }
        }
    }
    var image: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        image.image = UIImage(systemName: "checkmark.circle")
        self.addSubview(image)
        
        self.addTarget(self, action: #selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.checker = false
        
        image.snp.makeConstraints { make in
            make.size.height.equalTo(self.frame.size.height)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            checker = !checker
        }
    }
}
