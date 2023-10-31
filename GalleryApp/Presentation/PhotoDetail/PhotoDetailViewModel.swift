//
//  PhotoDetailViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 15.10.2022.
//

import Foundation
import RxSwift
import RxRelay

class PhotoDetailViewModel {
    // MARK: - Properties
    let galleryManager: GalleryManager
    
    var images: [GalleryImage]
    var index: IndexPath {
        didSet {
            self.indexAsObservable.accept(index)
        }
    }
    var indexAsObservable: BehaviorRelay<IndexPath>
    
    enum NavigationDirection {
        case previous
        case next
    }
    
    // MARK: - Init
    internal init(galleryManager: GalleryManager, settings: PhotoDetailModel) {
        self.images = settings.selectedImages
        self.index = settings.selectedIndex
        self.indexAsObservable = BehaviorRelay<IndexPath>(value: index)
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
    
    func showImage(_ navigationDirection: NavigationDirection) {
        switch navigationDirection {
        case .previous:
            if self.index.item > 0 {
                self.index.row -= 1
            }
        case .next:
            if index.item < images.count-1 {
                self.index.row += 1
            }
        }
    }
}
