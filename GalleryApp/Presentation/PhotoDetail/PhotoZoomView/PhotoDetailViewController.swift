//
//  PhotoDetailViewControllerNew.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.01.2022.
//

import UIKit
import simd
import RxSwift

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Properties
    var singleTapGestureRecognizer = UITapGestureRecognizer()
    var swipeDownGestureRecognizer = {
        let view = UISwipeGestureRecognizer()
        view.direction = .down
        return view
    }()
    let screenView = PhotoDetailView()
    var photoSliderViewController: PhotoSlideViewController!
    var photoDetailViewSettings: PhotoDetailViewControllerSettings
    var galleryManager: GalleryManager
    
    let disposeBag = DisposeBag()
    
    enum ScreenMode {
        case full, normal
    }
    var currentMode: ScreenMode = .normal
    
    // MARK: - Init
    internal init(galleryInteractor: GalleryManager, settings: PhotoDetailViewControllerSettings) {
        self.galleryManager = galleryInteractor
        self.photoDetailViewSettings = settings
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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        self.setupViews()
                
        self.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        self.view.addGestureRecognizer(self.swipeDownGestureRecognizer)
                
        
        self.bindInteractions()        
        let imagesToShow = photoDetailViewSettings.selectedImages.map {
            UIImage(contentsOfFile: self.galleryManager.resolvePathFor(imageName: $0.fileName))!
        }
        
        let photoSliderViewController = PhotoSlideViewController(images: imagesToShow, index: photoDetailViewSettings.selectedIndex)
        self.add(photoSliderViewController)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
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
    
    // MARK: - Binding Interactions
    private func bindInteractions() {
        self.screenView.closeButton.rx.tap.subscribe(onNext:  { [weak self] in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
                
        singleTapGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            self?.didSingleTapWith(gestureRecognizer: event)
        }).disposed(by: disposeBag)
        
        swipeDownGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.dismiss(animated: true)
            }
    
            if key.charactersIgnoringModifiers == UIKeyCommand.inputLeftArrow {
                
            } else if key.charactersIgnoringModifiers == UIKeyCommand.inputRightArrow {
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
