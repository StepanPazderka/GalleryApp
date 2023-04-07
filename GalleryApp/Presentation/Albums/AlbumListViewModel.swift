//
//  AlbumListViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 12.10.2022.
//

import Foundation
import RxCocoa

class AlbumListViewModel {
    
    let galleryManager: GalleryManager
    let showErrorCantAddImageToAlbum = BehaviorRelay(value: false)
    let shouldDismiss = BehaviorRelay(value: false)
    
    init(galleryManager: GalleryManager) {
        self.galleryManager = galleryManager
    }

    func moveToAlbum(images: [String], album: UUID) {
        do {
            try self.galleryManager.move(Image: AlbumImage(fileName: images.first!, date: Date()), toAlbum: album) {
                self.shouldDismiss.accept(true)
            }
        } catch MoveImageError.imageAlreadyInAlbum {
            showErrorCantAddImageToAlbum.accept(true)
        } catch {
            shouldDismiss.accept(true)
        }
    }
}
