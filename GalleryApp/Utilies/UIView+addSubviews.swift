//
//  UIView+addSubviews.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 19.10.2022.
//

import Foundation
import UIKit

extension UIView {
    
    /**
     Add mutliple subviews with single function
    */
    func addSubviews(_ views: UIView...) {
        for view in views {
            self.addSubview(view)
        }
    }
}
