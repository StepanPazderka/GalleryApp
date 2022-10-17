//
//  PhotoProperties.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.10.2022.
//

import Foundation
import UIKit

class PhotoPropertiesViewController: UIViewController {
    
    // MARK: - Aliases
    typealias ScreenView = PhotoPropertiesView
    
    // MARK: - Properties
    let viewModel: PhotoPropertiesViewModel
    lazy var screenView = ScreenView()
    
    // MARK: - Init
    init(viewModel: PhotoPropertiesViewModel)
    {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        self.view = screenView
        self.screenView.imageView.image = UIImage(contentsOfFile: viewModel.photoIDs.first!)
        self.screenView.photoSizeLabel.text = "\(NSLocalizedString("kFileSize", comment: "")) \(ByteCountFormatter().string(fromByteCount: Int64(viewModel.getFileSize())))"
        if let date = viewModel.getFileModifiedDate() {
            self.screenView.photoDateLabel.text = "\(NSLocalizedString("kFileDate", comment: "")) \(date)"
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
