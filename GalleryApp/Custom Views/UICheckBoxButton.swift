//
//  CheckBox.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 18.01.2021.
//

import UIKit
import SnapKit
import RxCocoa

@MainActor class UICheckBoxButton: UIButton {
    var checker: Bool = false {
        didSet {
            if checker == false {
                checkBoxImageView.image = UIImage(systemName: "checkmark.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .light))
            } else {
                checkBoxImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .light))
            }
        }
    }
    
    var checkBoxImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
        self.layoutViews()
        self.bindInteractions()
        self.checker = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.checkBoxImageView.image = UIImage(systemName: "checkmark.circle")
        self.titleLabel?.textAlignment = .right
        self.addSubview(checkBoxImageView)
    }
    
    func layoutViews() {
        self.checkBoxImageView.snp.makeConstraints { make in
            make.size.height.equalTo(self.frame.size.height)
            make.centerY.equalToSuperview()
        }
        
        self.titleLabel?.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }
    
    func bindInteractions() {
        self.addTarget(self, action: #selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
    }

    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            checker = !checker
        }
    }
}
