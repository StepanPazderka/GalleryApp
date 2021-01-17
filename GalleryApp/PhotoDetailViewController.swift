//
//  PhotoDetailViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 19.12.2020.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    var delegate: UIViewController!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.maximumZoomScale = 10
        scrollView.minimumZoomScale = 1
        
        scrollView.delegate = self
        
        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("CANCEL", comment: "Cancel"),
            action: #selector(didInvokeCancel),
            input: UIKeyCommand.inputEscape
        ))
        
        // Do any additional setup after loading the view.
    }
    
    @objc func didInvokeCancel() {
        delegate.dismiss(animated: true, completion: nil)
    }

    @IBAction func closeScreen(_ sender: Any) {
        delegate.dismiss(animated: true, completion: nil)
    }
}

extension PhotoDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1.0 {
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height

                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                
                let conditionLeft = newWidth*scrollView.zoomScale > imageView.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                
                let conditionTop = newHeight * scrollView.zoomScale > imageView.frame.height
                
                let top = 0.5 * (conditionTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        }
    }
}
