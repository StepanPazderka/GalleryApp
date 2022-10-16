//
//  PhotoDetailViewControllerNew.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.01.2022.
//

import UIKit
import simd
import RxSwift
import ImageSlideshow

class PhotoDetailViewController: UIViewController {
    
    var singleTapGestureRecognizer: UITapGestureRecognizer!
    let screenView = PhotoDetailView()
    var panGestureRecognizer: UIPanGestureRecognizer!
    var photoDetailView: PhotoDetailViewControllerSettings
    var galleryManager: GalleryManager
    var sidebar: SidebarViewController
    let disposeBag = DisposeBag()
    
    enum ScreenMode {
        case full, normal
    }
    var currentMode: ScreenMode = .normal
    
    // MARK: - Init
    internal init(galleryInteractor: GalleryManager, sidebar: SidebarViewController, settings: PhotoDetailViewControllerSettings) {
        self.galleryManager = galleryInteractor
        self.photoDetailView = settings
        self.sidebar = sidebar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        self.view = screenView
        self.view.backgroundColor = .white
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()

        self.view.backgroundColor = .none
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanWith(gestureRecognizer:)))
        self.panGestureRecognizer.delegate = self
        
        self.singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapWith(gestureRecognizer:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        self.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        let images = photoDetailView.selectedImages
        
        let firstImages = photoDetailView.selectedImages[0..<photoDetailView.selectedIndex]
        let endingImages = photoDetailView.selectedImages[photoDetailView.selectedIndex..<photoDetailView.selectedImages.endIndex]
        let newArray = Array(endingImages + firstImages)
        
        let selectedImage = photoDetailView.selectedImages[photoDetailView.selectedIndex].fileName
        let imagePath =  galleryManager.selectedGalleryPath.appendingPathComponent(selectedImage)

        let imagesSources: [ImageSource] = newArray.compactMap {
            let image = UIImage(contentsOfFile: galleryManager.selectedGalleryPath.appendingPathComponent($0.fileName).relativePath)
            if let image = image {
                let imageSource = ImageSource(image: image)
                return imageSource
            }
            return nil
        }
        
        self.bindInteractions()
        self.screenView.imageSlideShow.setImageInputs(imagesSources)
    }
    
    @objc func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        if self.currentMode == .full {
            changeScreenMode(to: .normal)
            self.currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            self.currentMode = .full
        }
    }
    
    func bindInteractions() {
        self.screenView.closeButton.rx.tap.subscribe(onNext:  {
            self.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        self.screenView.imageSlideShow.delegate = self
    }
    
    
    @objc func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            print("Panning began")
        case .ended:
            print("Panning ended")
        @unknown default:
            break
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.dismiss(animated: true)
            }
        }
    }
    
    func changeScreenMode(to: ScreenMode) {
        if to == .full {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.view.backgroundColor = .black
                            
            }, completion: { completed in
            })
        } else {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: {
                            if #available(iOS 13.0, *) {
                                self.view.backgroundColor = .systemBackground
                            } else {
                                self.view.backgroundColor = .white
                            }
            }, completion: { completed in
            })
        }
    }
}

extension PhotoDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: self.view)
            
            var velocityCheck : Bool = false
            
            if UIDevice.current.orientation.isLandscape {
                velocityCheck = velocity.x < 0
            }
            else {
                velocityCheck = velocity.y < 0
            }
            if velocityCheck {
                return false
            }
        }
        
        return true
    }
}

extension PhotoDetailViewController: UIPageViewControllerDelegate {
        
}


extension PhotoDetailViewController: ImageSlideshowDelegate {
    
}
