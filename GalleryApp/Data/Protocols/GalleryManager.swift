//
//  GalleryManagerProtocol.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 05.11.2023.
//

import Foundation
import RxCocoa
import RxSwift

protocol GalleryManager {
    
    var selectedGalleryPath: URL { get }
    var selectedGalleryIndexRelay: BehaviorRelay<GalleryIndex> { get }
    var libraryPath: URL { get }
    
    func galleryObservable() -> Observable<GalleryIndex>
    func delete(album: UUID)
    func delete(gallery: String)
    func delete(images: [GalleryImage])
    
    func duplicateAlbum(index: AlbumIndex) -> AlbumIndex
    func loadGalleryIndex(named galleryName: String?) -> GalleryIndex?
    func move(Image: GalleryImage, toAlbum: UUID, callback: (() -> Void)?) throws
    func updateAlbumIndex(index: AlbumIndex)
    @discardableResult func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex
    @discardableResult func rebuildGalleryIndex() -> GalleryIndex
    func buildThumbnail(forImage albumImage: GalleryImage)
    func loadAlbumIndex(id: UUID) -> AlbumIndex?
    func loadAlbumImage(id: String) -> GalleryImage?
    func update(image: GalleryImage)
    
    func resolveThumbPathFor(imageName: String) -> String
    func resolvePathFor(imageName: String) -> String
    
    func loadAlbumIndexAsObservable(id: UUID) -> Observable<AlbumIndex>
    func createAlbum(name: String, parentAlbum: UUID?) throws
}

extension GalleryManager {
    func move(Image: GalleryImage, toAlbum: UUID, callback: (() -> Void)? = nil) throws {
        try self.move(Image: Image, toAlbum: toAlbum, callback: {})
    }
    
    func loadGalleryIndex(named galleryName: String? = nil) -> GalleryIndex? {
        self.loadGalleryIndex(named: galleryName)
    }
    
    func createAlbum(name: String, parentAlbum: UUID? = nil) throws {
        try self.createAlbum(name: name, parentAlbum: parentAlbum)
    }
}
