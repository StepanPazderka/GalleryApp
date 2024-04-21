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
							let thumbnailFileName = albumIndex.thumbnail ?? albumIndex.images.first?.fileName
							
							if let fileName = thumbnailFileName {
								let thumbnailPath = self.galleryManager.pathResolver.selectedGalleryPath.appendingPathComponent(fileName)
								thumbnailImage = UIImage(contentsOfFile: thumbnailPath.relativePath)
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
		self.settingsManager.get(key: .selectedGallery)
    }
}
