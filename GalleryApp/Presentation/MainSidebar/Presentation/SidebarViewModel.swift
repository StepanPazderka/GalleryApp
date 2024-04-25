//
//  MainSideBarViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.12.2021.
//

import Foundation
import RxSwift

class SidebarViewModel {
	
	// MARK: -- Properties
	private let galleryManager: GalleryManager
	private let settingsManager: SettingsManagerImpl
	private let pathResolver: PathResolver
	
	let disposeBag = DisposeBag()
	
	let mainButonsSection = SidebarSectionModel(type: .mainButtons, name: NSLocalizedString("kMAIN", comment: "Main buttons"), items: [
		SidebarItem(title: NSLocalizedString("kALLPHOTOS", comment: "Title for sidebar cell to show All Photos in library"), image: nil, buttonType: .allPhotos)
	])
	
	init(galleryInteractor: GalleryManager, settingsManager: SettingsManagerImpl, pathResolver: PathResolver) {
		self.galleryManager = galleryInteractor
		self.settingsManager = settingsManager
		self.pathResolver = pathResolver
	}
	
	func renameAlbum(id: UUID, withNewAlbumName: String) throws {
		if var albumIndex = self.galleryManager.loadAlbumIndex(with: id) {
			albumIndex.name = withNewAlbumName
			try self.galleryManager.updateAlbumIndex(index: albumIndex)
		}
	}
	
	func duplicateAlbum(id: UUID) {
		if let album: AlbumIndex = self.galleryManager.loadAlbumIndex(with: id) {
			self.galleryManager.duplicate(album: album)
		}
	}
	
	func loadSidebarContent() -> Observable<[SidebarSectionModel]> {
		return galleryManager
			.loadCurrentGalleryIndexAsObservable()
			.flatMap { [unowned self] galleryIndex -> Observable<[SidebarSectionModel]> in
				let albumObservables = galleryIndex.albums.compactMap { albumID -> Observable<SidebarItem?> in
					self.galleryManager.loadAlbumIndexAsObservable(id: albumID)
						.map { [unowned self] albumIndex -> SidebarItem? in
							var thumbnailImage: UIImage?
							if let thumbnailFileName = albumIndex.thumbnail, !thumbnailFileName.isEmpty {
								let thumbnailPath = self.pathResolver.selectedGalleryPath.appendingPathComponent(thumbnailFileName)
								thumbnailImage = UIImage(contentsOfFile: thumbnailPath.relativePath)
							} else {
								if let thumbnailFileName = albumIndex.images.first?.fileName {
									let thumbnailPath = self.pathResolver.selectedGalleryPath.appendingPathComponent(thumbnailFileName)
									thumbnailImage = UIImage(contentsOfFile: thumbnailPath.relativePath)
								}
							}
							
							return SidebarItem(
								id: UUID(uuidString: albumIndex.id.uuidString),
								title: albumIndex.name,
								image: thumbnailImage,
								buttonType: .album
							)
						}
						.catchAndReturn(nil)
				}
				
				return Observable.combineLatest(albumObservables)
					.map { albumItems in
						let albumButtons = SidebarSectionModel(type: .albumButtons, name: "Albums", items: albumItems.compactMap { $0 })
						return [self.mainButonsSection, albumButtons]
					}
			}
	}
	
	
	func createAlbum(name: String, parentAlbumID: UUID? = nil,  ID: UUID? = nil) {
		do {
			if let parentAlbumID {
				try galleryManager.createAlbum(name: name, parentAlbum: parentAlbumID)
			} else {
				try galleryManager.createAlbum(name: name, parentAlbum: nil)
			}
		} catch {
			
		}
	}
	
	func removeThumbnail(albumID: UUID) {
		if var albumIndex = self.galleryManager.loadAlbumIndex(with: albumID) {
			albumIndex.thumbnail = nil
			try? self.galleryManager.updateAlbumIndex(index: albumIndex)
		}
	}
	
	func deleteAlbum(id: UUID) {
		self.galleryManager.delete(album: id)
	}
	
	func getSelectedLibraryNameAsObservable() -> Observable<String> {
		self.settingsManager.getCurrentlySelectedGalleryIDAsObservable()
			.catch { [weak self] error -> Observable<String> in
				if let returnID = self?.galleryManager.loadGalleries().compactMap({ $0.first?.id }).compactMap ({ $0.uuidString }) {
					return returnID
				} else {
					return .empty()
				}
			}
			.flatMapLatest { [weak self] galleryID -> Observable<String> in
				guard let self = self else { return .empty() }
				return self.galleryManager.loadGalleries()
					.compactMap { [weak self] galleries -> String? in
						if let returnValue = galleries.first { $0.id.uuidString == galleryID }?.mainGalleryName {
							return returnValue
						} else {
							if let firstGallery = galleries.first {
								self?.settingsManager.setSelectedGallery(id: firstGallery.id.uuidString)
							}
							return galleries.first?.mainGalleryName
						}
					}
			}
	}
}
