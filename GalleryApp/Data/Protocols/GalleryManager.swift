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
    
    // MARK: - Propertes
    var pathResolver: PathResolver { get }
    var selectedGalleryIndexRelay: BehaviorRelay<GalleryIndex> { get }
    
    // MARK: - Loading
    func loadImageAsObservable(with: UUID) -> Observable<GalleryImage>
    
    func loadAlbumIndex(with: UUID) -> AlbumIndex?
    func loadAlbumIndexAsObservable(id: UUID) -> Observable<AlbumIndex>
    
    func load(galleryIndex: String?) -> GalleryIndex?
    func loadGalleryIndexAsObservable() -> Observable<GalleryIndex>
    
    // MARK: - Writing
    func write(images: [GalleryImage])
    @discardableResult func createAlbum(name: String, parentAlbum: UUID?) throws -> AlbumIndex
    
    // MARK: - Updating
    func update(image: GalleryImage)
    @discardableResult func updateAlbumIndex(index: AlbumIndex) throws -> AlbumIndex
    @discardableResult func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex
    
    // MARK: - Deletion
    func delete(album: UUID)
    func delete(gallery: String)
    func delete(images: [GalleryImage])
    
    // MARK: - Duplication
    func duplicate(album: AlbumIndex) -> AlbumIndex
    func duplicate(images: [GalleryImage], inAlbum album: AlbumIndex?) throws
    
    // MARK: - Special
    func move(Image: GalleryImage, toAlbum: UUID, callback: (() -> Void)?) throws
    
    func buildThumbnail(forImage albumImage: GalleryImage)
}

extension GalleryManager {
    func move(Image: GalleryImage, toAlbum: UUID, callback: (() -> Void)? = nil) throws {
        try self.move(Image: Image, toAlbum: toAlbum, callback: {})
    }
}