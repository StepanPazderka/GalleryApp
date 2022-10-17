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
        self.screenView.photoSizeLabel.text = ByteCountFormatter().string(fromByteCount: Int64(viewModel.getFileSize()))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
