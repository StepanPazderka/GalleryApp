//
//  UIImageView+contentClippingRect.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.10.2023.
//

import Foundation
import UIKit

extension UIImageView {
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        
        let contentScale = image.size.width / image.size.height
        let viewScale = bounds.width / bounds.height
        
        switch contentMode {
        case .scaleAspectFit:
            if contentScale < viewScale {
                let scale = bounds.height / image.size.height
                let width = scale * image.size.width
                let xOffset = (bounds.width - width) * 0.5
                return CGRect(x: xOffset, y: 0, width: width, height: bounds.height)
            } else {
                let scale = bounds.width / image.size.width
                let height = scale * image.size.height
                let yOffset = (bounds.height - height) * 0.5
                return CGRect(x: 0, y: yOffset, width: bounds.width, height: height)
            }
            
        case .scaleAspectFill:
            if contentScale > viewScale {
                let scale = bounds.height / image.size.height
                let width = scale * image.size.width
                let xOffset = (bounds.width - width) * 0.5
                return CGRect(x: xOffset, y: 0, width: width, height: bounds.height)
            } else {
                let scale = bounds.width / image.size.width
                let height = scale * image.size.height
                let yOffset = (bounds.height - height) * 0.5
                return CGRect(x: 0, y: yOffset, width: bounds.width, height: height)
            }
            
        case .center:
            let xOffset = (bounds.width - image.size.width) * 0.5
            let yOffset = (bounds.height - image.size.height) * 0.5
            return CGRect(x: xOffset, y: yOffset, width: image.size.width, height: image.size.height)
            
        case .top:
            let xOffset = (bounds.width - image.size.width) * 0.5
            return CGRect(x: xOffset, y: 0, width: image.size.width, height: image.size.height)
            
        case .bottom:
            let xOffset = (bounds.width - image.size.width) * 0.5
            return CGRect(x: xOffset, y: bounds.height - image.size.height, width: image.size.width, height: image.size.height)
            
        case .left:
            let yOffset = (bounds.height - image.size.height) * 0.5
            return CGRect(x: 0, y: yOffset, width: image.size.width, height: image.size.height)
            
        case .right:
            let yOffset = (bounds.height - image.size.height) * 0.5
            return CGRect(x: bounds.width - image.size.width, y: yOffset, width: image.size.width, height: image.size.height)
            
        default:
            return bounds
        }
    }
}
