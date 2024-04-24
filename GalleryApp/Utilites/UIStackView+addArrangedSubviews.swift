//
//  UIStackView+addArrangedSubviews.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 23.09.2023.
//

import Foundation
import UIKit

extension UIStackView {
    /**
     Add mutliple subviews with single function
    */
    func addArrangedSubviews(_ views: UIView...) {
        for view in views {
            self.addArrangedSubview(view)
        }
    }
}
