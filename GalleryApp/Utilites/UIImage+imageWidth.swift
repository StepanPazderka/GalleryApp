//
//  UIImage+imageWidth.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 07.12.2021.
//

import Foundation
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
