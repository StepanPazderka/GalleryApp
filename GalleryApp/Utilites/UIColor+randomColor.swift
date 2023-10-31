//
//  UIColor+randomColor.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.09.2023.
//

import Foundation
import UIKit

extension UIColor {
    static func randomColor() -> UIColor {
        let red = Double.random(in: 0..<1)
        let green = Double.random(in: 0..<1)
        let blue = Double.random(in: 0..<1)

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
