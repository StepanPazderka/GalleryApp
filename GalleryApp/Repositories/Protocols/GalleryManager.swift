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
        
    // MARK: - Loading
    func loadImageAsObservable(with: UUID) -> Observable<GalleryImage>
    
    // MARK: - Create
	func add(images: [GalleryImage], toAlbum: AlbumIndex?)
    @discardableResult func createAlbum(name: String, parentAlbum: UUID?) throws -> AlbumIndex
	@discardableResult func createGalleryIndex(name: String) throws -> GalleryIndex
	
	// MARK: - Read
	func loadCurrentGalleryIndex() -> GalleryIndex?
	func loadCurrentGalleryIndexAsObservable() -> Observable<GalleryIndex>
	func load(galleryIndex: String?) -> GalleryIndex?
	func loadGalleryIndexAsObservable() -> Observable<GalleryIndex>
	func loadGalleriesAsObservable() -> Observable<[GalleryIndex]>
	func getCurrentlySelectedGalleryIDAsObservable() -> Observable<String>
	
	func loadAlbumIndex(with: UUID) -> AlbumIndex?
	func loadAlbumIndexAsObservable(id: UUID) -> Observable<AlbumIndex>
		
    // MARK: - Updating
    func update(image: GalleryImage)
    @discardableResult func updateAlbumIndex(index: AlbumIndex) throws -> AlbumIndex
    @discardableResult func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex
    
    // MARK: - Deletion
    func delete(album: UUID) throws
    func deleteGallery(named galleryName: String)
    func delete(images: [GalleryImage])
    
    // MARK: - Duplication
	@discardableResult func duplicate(album: AlbumIndex) -> AlbumIndex
    func duplicate(images: [GalleryImage], inAlbum album: AlbumIndex?) throws
    
    // MARK: - Special
    func move(images: [GalleryImage], toAlbum: UUID, callback: (() -> Void)?) throws
    func buildThumbnail(forImage albumImage: GalleryImage)
}

extension GalleryManager {
    func move(images: [GalleryImage], toAlbum: UUID, callback: (() -> Void)? = nil) throws {
        try self.move(images: images, toAlbum: toAlbum, callback: {})
    }
}
