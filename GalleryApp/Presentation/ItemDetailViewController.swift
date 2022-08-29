//
//  ItemDetailViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.06.2022.
//

import Foundation
import UIKit

class ItemDetailViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = .red
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
