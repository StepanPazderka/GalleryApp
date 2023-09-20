//
//  PhotoDetailViewControllerNew.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.01.2022.
//

import UIKit
import RxSwift
import SnapKit

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Properties
    var singleTapGestureRecognizer = UITapGestureRecognizer()
    
    let screenView = PhotoDetailView()
    var viewModel: PhotoDetailViewModel
    
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    internal init(viewModel: PhotoDetailViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        self.screenView.addGestureRecognizer(screenView.swipeDownGestureRecognizer)
        self.setupViews()
        self.bindInteractions()
    }
    
    // MARK: - Layout
    private func setupViews() {
        self.view = screenView
        self.view.backgroundColor = .systemBackground
        screenView.scrollView.delegate = self

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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - Data Binding
    private func bindData() {
        let numberOfImages = viewModel.getImages().count
        
        let calculatedStackViewWidth: Double = screenView.bounds.width * Double(numberOfImages)
        
        screenView.stackView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(numberOfImages)

        }
        screenView.stackView.sizeToFit()
        for imageview in screenView.stackView.arrangedSubviews {
            imageview.layoutIfNeeded()
        }
        
        for image in viewModel.getImages() {
            let imageView = PanZoomImageView(frame: screenView.bounds)
            imageView.image = UIImage(contentsOfFile: image.fileName)
            imageView.contentMode = .scaleAspectFit
            self.screenView.stackView.addArrangedSubview(imageView)
        }
        screenView.scrollView.contentSize = screenView.stackView.frame.size
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.bindData()
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { [weak self] in
            guard let self = self else { return }
            self.scrollToPage(page: self.viewModel.index, animated: false)
        }
    }
    
    func scrollToPage(page: Int, animated: Bool) {
        var function: () -> () = {
            var frame: CGRect = self.screenView.scrollView.frame
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0
            self.screenView.scrollView.contentOffset = frame.origin
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                function()
            })
        } else {
            function()
        }
       
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.dismiss(animated: true)
            }
            
            if key.charactersIgnoringModifiers == UIKeyCommand.inputLeftArrow {
                if viewModel.index == 0 {
                    viewModel.index = viewModel.images.count-1
                } else {
                    viewModel.index = viewModel.index-1
                }
                scrollToPage(page: viewModel.index, animated: false)
            } else if key.charactersIgnoringModifiers == UIKeyCommand.inputRightArrow {
                if viewModel.index == viewModel.images.count-1 {
                    viewModel.index = 0
                } else {
                    viewModel.index += 1
                }
                scrollToPage(page: viewModel.index, animated: false)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.01) { [weak self] in
            guard let self = self else { return }
            self.screenView.stackView.layoutSubviews()
            self.screenView.stackView.invalidateIntrinsicContentSize()
            self.screenView.scrollView.contentSize = self.screenView.stackView.frame.size
            self.scrollToPage(page: self.viewModel.index, animated: false)
        }
    }
}

extension PhotoDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let number = screenView.scrollView.contentOffset.x / screenView.scrollView.frame.size.width
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            if viewModel.index != Int(number) {
                viewModel.index = Int(number)
                
                for imageView in screenView.stackView.arrangedSubviews {
                    (imageView as! UIScrollView).zoomScale = 1
                }
            }
        }
    }
}
