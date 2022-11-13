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
    
    var singleTapGestureRecognizer = UITapGestureRecognizer()
    var swipeDownGestureRecognizer = {
        let view = UISwipeGestureRecognizer()
        view.direction = .down
        return view
    }()
    let screenView = PhotoDetailView()
    var photoDetailView: PhotoDetailViewControllerSettings
    var galleryManager: GalleryManager
    
    let disposeBag = DisposeBag()
    
    enum ScreenMode {
        case full, normal
    }
    var currentMode: ScreenMode = .normal
    
    // MARK: - Init
    internal init(galleryInteractor: GalleryManager, settings: PhotoDetailViewControllerSettings) {
        self.galleryManager = galleryInteractor
        self.photoDetailView = settings
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    private func setupViews() {
        self.view = screenView
        self.view.backgroundColor = .systemBackground
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        self.setupViews()
                
        self.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        self.view.addGestureRecognizer(self.swipeDownGestureRecognizer)
                
        let newArray = Array(photoDetailView.selectedImages)
        
        let imagesSources: [ImageSource] = newArray.compactMap {
            let image = UIImage(contentsOfFile: galleryManager.selectedGalleryPath.appendingPathComponent($0.fileName).relativePath)
            if let image = image {
                let imageSource = ImageSource(image: image)
                return imageSource
            }
            return nil
        }
        self.screenView.imageSlideShow.setImageInputs(imagesSources)
        
                self.screenView.imageSlideShow.setCurrentPage(photoDetailView.selectedIndex, animated: false)

        
        self.bindInteractions()
    }

    
    @objc func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        self.screenView.imageSlideShow.presentFullScreenController(from: self)
        
        if self.currentMode == .full {
            changeScreenMode(to: .normal)
            self.currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            self.currentMode = .full
        }
    }
    
    // MARK: - Binding Interactions
    private func bindInteractions() {
        self.screenView.closeButton.rx.tap.subscribe(onNext:  { [weak self] in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        self.screenView.imageSlideShow.delegate = self
        
        singleTapGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            self?.didSingleTapWith(gestureRecognizer: event)
        }).disposed(by: disposeBag)
        
        swipeDownGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.dismiss(animated: true)
            }
    
            if key.charactersIgnoringModifiers == UIKeyCommand.inputLeftArrow {
                self.screenView.imageSlideShow.previousPage(animated: true)
            } else if key.charactersIgnoringModifiers == UIKeyCommand.inputRightArrow {
                self.screenView.imageSlideShow.nextPage(animated: true)
            }
        }
    }
    
    func changeScreenMode(to: ScreenMode) {
        if to == .full {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: { [weak self] in
                            self?.view.backgroundColor = .black
                            self?.screenView.closeButton.isHidden = true

            }, completion: { completed in
            })
        } else {
            
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: { [weak self] in
                            if #available(iOS 13.0, *) {
                                self?.view.backgroundColor = .systemBackground
                            } else {
                                self?.view.backgroundColor = .white
                            }
                            self?.screenView.closeButton.isHidden = false
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

extension PhotoDetailViewController: ImageSlideshowDelegate {
    func imageSlideshow(_ imageSlideshow: ImageSlideshow, didChangeCurrentPageTo page: Int) {
        
    }
}
