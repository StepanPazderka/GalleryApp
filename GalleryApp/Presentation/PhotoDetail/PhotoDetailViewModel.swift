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
    
    var images: [GalleryImage]
    var index: IndexPath
    
    // MARK: - Init
    internal init(galleryManager: GalleryManager, settings: PhotoDetailModel) {
        self.images = settings.selectedImages
        self.index = settings.selectedIndex
        self.galleryManager = galleryManager
    }
    
    func getImages() -> [GalleryImage] {
        self.images.map { image in
            var mutatedImage = image
            mutatedImage.fileName = galleryManager.resolvePathFor(imageName: image.fileName)
            return mutatedImage
        }
    }
    
    func resolveThumbPathFor(image: String) -> String {
        galleryManager.resolvePathFor(imageName: image)
    }
}
