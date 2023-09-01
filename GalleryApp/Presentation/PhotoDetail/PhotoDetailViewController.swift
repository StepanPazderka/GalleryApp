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
        LightboxConfig.hideStatusBar = true
        LightboxConfig.InfoLabel.enabled = false
        LightboxConfig.PageIndicator.enabled = false
        
        let images = viewModel.images.map { image in
            LightboxImage(image: UIImage(contentsOfFile: galleryManager.resolvePathFor(imageName: image.fileName))!)
        }
        
        self.lightboxController = LightboxController(images: images, startIndex: viewModel.index)
        self.lightboxController.dynamicBackground = false
        self.lightboxController.view.frame = view.frame
        self.lightboxController.pageDelegate = self
        self.add(lightboxController)
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
    
    // MARK: - Binding Interactions
    private func bindInteractions() {
        self.screenView.closeButton.rx.tap.subscribe(onNext:  { [weak self] in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        self.screenView.swipeDownGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            
            guard let self = self else { return }
            
            let translation = screenView.swipeDownGestureRecognizer.translation(in: view)
            
            switch self.screenView.swipeDownGestureRecognizer.state {
            case .changed:
                if translation.y > 0 {  // Only allow dragging downwards
                    view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                }
            case .ended:
                // Dismiss the view controller if dragged beyond a certain distance
                if translation.y > 100 {
                    dismiss(animated: true, completion: nil)
                } else {
                    // Reset the transformation if the distance is less than the threshold
                    UIView.animate(withDuration: 0.3) {
                        self.screenView.transform = CGAffineTransform.identity
                    }
                }
            default:
                break
            }
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
}

extension PhotoDetailViewController: LightboxControllerPageDelegate {
    func lightboxController(_ controller: Lightbox.LightboxController, didMoveToPage page: Int) {
        
    }
}
