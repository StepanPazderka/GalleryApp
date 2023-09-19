//
//  PhotoDetailViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 15.10.2022.
//

import Foundation

class PhotoDetailViewModel {
    // MARK: - Properties
    let galleryManager: GalleryManager
    
    var images: [AlbumImage]
    var index: Int
    
    // MARK: - Init
    internal init(galleryManager: GalleryManager, settings: PhotoDetailModel) {
        self.images = settings.selectedImages
        self.index = settings.selectedIndex
        self.galleryManager = galleryManager
    }
    
    func getImages() -> [AlbumImage] {
        self.images.map { image in
            var mutatedImage = image
            mutatedImage.fileName = galleryManager.resolvePathFor(imageName: image.fileName)
            return mutatedImage
        }
    }
}
