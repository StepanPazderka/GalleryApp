//
//  ImageScrollView.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 19.07.2023.
//

import Foundation
import UIKit

class ImageScrollView: UIScrollView {
    var imageView: UIImageView
    
    private var oldBoundsSize: CGSize = .zero
    
    override init(frame: CGRect) {
        self.imageView = UIImageView(frame: .zero)
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(image: UIImage) {
        self.imageView = UIImageView(image: image)
        
        super.init(frame: .zero)
        
        self.delegate = self
    }
    
    override func layoutSubviews() {
        if oldBoundsSize != self.bounds.size {
            oldBoundsSize = self.bounds.size
            
            self.contentSize = self.imageView.bounds.size
            self.imageView = UIImageView(image: self.imageView.image)
            self.addSubviews(imageView)
            
            setScrollViewBounds()
        }
        
        super.layoutSubviews()
    }
    
    func setScrollViewBounds() {
        let imageViewBounds = self.imageView.bounds.size
        let minimumZoomScale = min(self.bounds.width / imageViewBounds.width, self.bounds.height / imageViewBounds.height)
        
        self.contentSize = self.imageView.bounds.size
        
        self.minimumZoomScale = minimumZoomScale
        self.zoomScale = minimumZoomScale
        self.maximumZoomScale = minimumZoomScale * 30
    }
}

extension ImageScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2
        } else {
            contentsFrame.origin.x = 0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2
        } else {
            contentsFrame.origin.y = 0
        }
        
        imageView.frame = contentsFrame
        
        if scrollView.zoomScale > 3.0 {
            imageView.layer.magnificationFilter = .nearest
        } else {
            imageView.layer.magnificationFilter = .linear
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        setScrollViewBounds()
    }
}
