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
        galleryManager
            .loadCurrentGalleryIndexAsObservable()
            .map { galleryIndex in
				let mainButonsSection = SidebarSectionModel(type: .mainButtons, name: NSLocalizedString("kMAIN", comment: "Main buttons"), items: [
                    SidebarItem(title: NSLocalizedString("kALLPHOTOS", comment: "Title for sidebar cell to show All Photos in library"), image: nil, buttonType: .allPhotos)
                ])
				let albumButtons = SidebarSectionModel(type: .albumButtons, name: "Albums", items: galleryIndex.albums.compactMap { albumID in
                    if let album = self.galleryManager.loadAlbumIndex(with: albumID) {
                        var thumbnailImage: UIImage?
                        
                        if let FirstAlbumImage = album.images.first {
                            let path = self.pathResolver.resolveThumbPathFor(imageName: FirstAlbumImage.fileName)
                            
                            let thumbnailImageURL = self.galleryManager.pathResolver.selectedGalleryPath.appendingPathComponent(FirstAlbumImage.fileName)
                            thumbnailImage = UIImage(contentsOfFile: path)
                        }
                        
                        if let thumbnail = album.thumbnail {
                            if !thumbnail.isEmpty && !album.images.isEmpty {
                                let thumbnailImageURL = self.galleryManager.pathResolver.selectedGalleryPath.appendingPathComponent(thumbnail)
                                thumbnailImage = UIImage(contentsOfFile: thumbnailImageURL.relativePath)
                            }
                        }
                        return SidebarItem(id: UUID(uuidString: albumID.uuidString), title: album.name, image: thumbnailImage ?? nil, buttonType: .album)
                    } else {
                        return nil
                    }
                })
                return [mainButonsSection, albumButtons]
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
        var albumIndex: AlbumIndex? = self.galleryManager.loadAlbumIndex(with: albumID)
        if var albumIndex {
            albumIndex.thumbnail = nil
            try? self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func deleteAlbum(id: UUID) {
        self.galleryManager.delete(album: id)
    }
    
    func getSelectedLibraryNameAsObservable() -> Observable<String> {
        self.settingsManager.selectedGalleryAsObservable
    }
}
