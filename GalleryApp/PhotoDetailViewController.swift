//
//  PhotoDetailViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 19.12.2020.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    var delegate: AllPhotos!
    var selectedIndex: Int!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.maximumZoomScale = 10
        scrollView.minimumZoomScale = 1
        
        scrollView.delegate = self
        imageView.image = UIImage(contentsOfFile: delegate.listedImages[selectedIndex].relativePath)
        
        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("CANCEL", comment: "Cancel"),
            action: #selector(didInvokeCancel),
            input: UIKeyCommand.inputEscape
        ))
        
        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("LEFT", comment: "Previous item"),
            action: #selector(selectPreviousItem),
            input: UIKeyCommand.inputLeftArrow
        ))
        
        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("RIGHT", comment: "Next item"),
            action: #selector(selectNextItem),
            input: UIKeyCommand.inputRightArrow
        ))
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction @objc func didInvokeCancel() {
        delegate.dismiss(animated: true, completion: nil)
    }

    @IBAction func selectPreviousItem(_ sender: Any) {
        if selectedIndex > 0 {
            selectedIndex = selectedIndex-1
        }
        imageView.image = UIImage(contentsOfFile: delegate.listedImages[selectedIndex].relativePath)
    }
    
    @IBAction func selectNextItem(_ sender: Any) {
        if selectedIndex < delegate.listedImages.count-1 {
            selectedIndex = selectedIndex+1
        }
        imageView.image = UIImage(contentsOfFile: delegate.listedImages[selectedIndex].relativePath)
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
