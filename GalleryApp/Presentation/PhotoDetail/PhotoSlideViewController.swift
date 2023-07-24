//
//  PhotoViewerViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.07.2023.
//

import Foundation
import UIKit
import SnapKit

class PhotoSlideItemViewController: UIViewController {
    var imageScrollView: ImageScrollView
    
    init(image: UIImage) {
        self.imageScrollView = ImageScrollView(image: image)

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imageScrollView)
        
        imageScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

class PhotoSlideViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var images: [UIImage] = [] // Your images here

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self

        for image in images {
            setViewControllers([newImagePageItemViewController(for: image)], direction: .forward, animated: false, completion: nil)
        }
    }
    
    init(images: [UIImage], index: Int) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.images = images
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PhotoSlideItemViewController,
              let index = images.firstIndex(where: { $0 == viewController.imageScrollView.imageView.image }),
              index > 0 else { return nil }

        return newImagePageItemViewController(for: images[index - 1])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PhotoSlideItemViewController,
              let index = images.firstIndex(where: { $0 == viewController.imageScrollView.imageView.image }),
              index < images.count - 1 else { return nil }

        return newImagePageItemViewController(for: images[index + 1])
    }
    
    func newImagePageItemViewController(for image: UIImage) -> PhotoSlideItemViewController {
        let viewController = PhotoSlideItemViewController(image: image)
        let imageScrollView = ImageScrollView(frame: view.bounds)
        imageScrollView.imageView.image = image
        viewController.imageScrollView = imageScrollView
        return viewController
    }
}

