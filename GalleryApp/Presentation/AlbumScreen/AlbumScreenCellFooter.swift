//
//  AlbumScreenFooter.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 27.04.2022.
//

import Foundation
import UIKit

class AlbumScreenCellFooter: UICollectionReusableView {
    static public let identifier = String(describing: AlbumScreenCellFooter.self)
    
    func setup() {
        self.backgroundColor = .red
    }
}
