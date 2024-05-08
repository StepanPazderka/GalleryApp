//
//  PhotoProperties.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class PhotoPropertiesViewController: UIViewController {
    
    // MARK: - Aliases
    typealias ScreenView = PhotoPropertiesView
    
    // MARK: - Properties
    let viewModel: PhotoPropertiesViewModel
    lazy var screenView = ScreenView()
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(viewModel: PhotoPropertiesViewModel)
    {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViews()
        self.bindData()
    }
    
    func setupViews() {
        self.view = screenView
        
        let imagesViews = [screenView.imageView1, screenView.imageView2, screenView.imageView3]
        
        for (index, imageView) in imagesViews.enumerated() {
            if index < viewModel.selectedImages.count {
				let resolvedImagePath = viewModel.resolveImagePaths().reversed()[index]
                imageView.image = UIImage(contentsOfFile: resolvedImagePath)
            }
        }

        if let fileType = viewModel.getFileType() {
            let localizedFileTypeText = NSLocalizedString("kFileType", comment: "")
            self.screenView.itemFileTypeLabel.text = "\(localizedFileTypeText) \(fileType)"
        }
        self.screenView.itemFileSizeLabel.text = "\(NSLocalizedString("kFileSize", comment: "")) \(ByteCountFormatter().string(fromByteCount: Int64(viewModel.getFileSize())))"
        
		// MARK: SETUP: Date Created Field
        if let date = viewModel.getFileCreationDate() {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .long
            dateFormatter.dateStyle = .long
            let localizedCreationDateText = NSLocalizedString("kFileCreationDate", comment: "")
            self.screenView.itemCreationDateLabel.text = "\(localizedCreationDateText) \(dateFormatter.string(from: date))"
        }
        
		// MARK: SETUP: Date Modified Field
        if let date = viewModel.getFileModifiedDate() {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .long
            dateFormatter.dateStyle = .long
            let localizedModifiedDateText = NSLocalizedString("kFileModifiedDate", comment: "")
            self.screenView.photoDateLabel.text = "\(localizedModifiedDateText) \(dateFormatter.string(from: date))"
        }
        
		
		// MARK: - SETUP: Text Field
		self.screenView.textView.delegate = self
		if viewModel.selectedImages.count > 1 {
			self.screenView.textView.isEditable = false
			self.screenView.textView.backgroundColor = .tertiarySystemFill
		}
    }
    
    func bindData() {
        self.viewModel
            .getPhotoTitleAsObservable()
            .asDriver(onErrorJustReturn: "")
            .drive(self.screenView.textView.rx.text)
            .disposed(by: disposeBag)
    }
	
	func setupTextField() {
		
	}
}

extension PhotoPropertiesViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        var updatedImage = viewModel.selectedImages.first!
        updatedImage.title = textView.text
        self.viewModel.update(image: updatedImage)
    }
}
