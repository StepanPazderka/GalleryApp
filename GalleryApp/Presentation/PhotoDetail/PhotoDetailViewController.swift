//
//  PhotoDetailViewControllerNew.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.01.2022.
//

import UIKit
import simd
import RxSwift
import Lightbox

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Properties
    var singleTapGestureRecognizer = UITapGestureRecognizer()
    
    let screenView = PhotoDetailView()
    var galleryManager: GalleryManager
    var viewModel: PhotoDetailViewModel
    
    var lightboxController: LightboxController!
    
    let disposeBag = DisposeBag()
    
    enum ScreenMode {
        case full, normal
    }
    var currentMode: ScreenMode = .normal
    
    // MARK: - Init
    internal init(galleryInteractor: GalleryManager, settings: PhotoDetailModel) {
        self.galleryManager = galleryInteractor
        self.viewModel = PhotoDetailViewModel(images: settings.selectedImages, index: settings.selectedIndex)
        
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
    
    private func setupLightbox() {
        
        let images = viewModel.images.map { image in
            LightboxImage(image: UIImage(contentsOfFile: galleryManager.resolvePathFor(imageName: image.fileName))!)
        }
        
        self.lightboxController = LightboxController(images: images, startIndex: viewModel.index)
        LightboxConfig.hideStatusBar = true
        lightboxController.dynamicBackground = false
        LightboxConfig.InfoLabel.enabled = false
        LightboxConfig.PageIndicator.enabled = false
        lightboxController.imageTouchDelegate = self
        
        self.add(lightboxController)
        
        lightboxController.view.frame = view.frame
        lightboxController.pageDelegate = self
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        self.setupViews()
        self.setupLightbox()
        
        self.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        self.view.addGestureRecognizer(self.screenView.swipeDownGestureRecognizer)
        
        self.bindInteractions()
        self.bindData()
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
    
    func switchScreenMode() {
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
        
        self.singleTapGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            self?.didSingleTapWith(gestureRecognizer: event)
        }).disposed(by: disposeBag)
        
        self.screenView.swipeDownGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    private func bindData() {
        
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.dismiss(animated: true)
            }
            
            if key.charactersIgnoringModifiers == UIKeyCommand.inputLeftArrow {
                lightboxController.previous()
            } else if key.charactersIgnoringModifiers == UIKeyCommand.inputRightArrow {
                lightboxController.next()
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

extension PhotoDetailViewController: LightboxControllerPageDelegate {
    func lightboxController(_ controller: Lightbox.LightboxController, didMoveToPage page: Int) {
        
    }
}

extension PhotoDetailViewController: LightboxControllerTouchDelegate {
    func lightboxController(_ controller: LightboxController, didTouch image: LightboxImage, at index: Int) {
        switchScreenMode()
    }
}
