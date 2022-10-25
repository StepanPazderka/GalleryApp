//
//  PhotoDetailViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 15.10.2022.
//

import Foundation

class PhotoDetailViewModel {
    
    // MARK: - Properties
    var images: [AlbumImage]
    var index: Int
    
    // MARK: - Init
    internal init(images: [AlbumImage], index: Int) {
        self.images = images
        self.index = index
    }
}
