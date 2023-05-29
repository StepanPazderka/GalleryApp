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
    private var galleryManager: GalleryManager
    private var settingsManager: SettingsManager
    
    let disposeBag = DisposeBag()
    
    init(galleryInteractor: GalleryManager, settingsManager: SettingsManager) {
        self.galleryManager = galleryInteractor
        self.settingsManager = settingsManager
    }
    
    func loadGalleryIndex() -> Observable<GalleryIndex> {
        galleryManager.selectedGalleryIndexRelay.asObservable()
    }
    
    func fetchAlbums() -> Observable<[UUID]> {
        return galleryManager.selectedGalleryIndexRelay.map { galleryIndex in
            return galleryIndex.albums
        }
    }
    
    func renameAlbum(id: UUID, withNewAlbumName: String) {
        if var albumIndex = self.galleryManager.loadAlbumIndex(id: id) {
            albumIndex.name = withNewAlbumName
            self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func duplicateAlbum(id: UUID) {
        if let album: AlbumIndex = self.galleryManager.loadAlbumIndex(id: id) {
            self.galleryManager.dubplicateAlbum(index: album)
        }
    }
    
    func loadSidebarContent() -> Observable<[SidebarSection]> {
        loadGalleryIndex().map { galleryIndex in
            let mainButonsSection = SidebarSection(category: "Main", items: [
                SidebarItem(id: UUID(), title: NSLocalizedString("kALLPHOTOS", comment: "Title for sidebar cell to show All Photos in library"), image: nil, buttonType: .allPhotos)
            ])
            let albumButtons = SidebarSection(category: "Albums", items: galleryIndex.albums.compactMap { albumID in
                if let album = self.galleryManager.loadAlbumIndex(id: albumID) {
                    var thumbnailImage: UIImage?

                    if let FirstAlbumImage = album.images.first {
                        let path = self.galleryManager.resolvePathFor(imageName: FirstAlbumImage.fileName)
                        
                        let thumbnailImageURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(FirstAlbumImage.fileName)
                        thumbnailImage = UIImage(contentsOfFile: path)
                    }
                    
                    if let thumbnail = album.thumbnail {
                        if !thumbnail.isEmpty {
                            let thumbnailImageURL = self.galleryManager.selectedGalleryPath.appendingPathComponent(thumbnail)
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
            if let parentAlbumID = parentAlbumID {
                try galleryManager.createAlbum(name: name, parentAlbum: parentAlbumID)
            } else {
                try galleryManager.createAlbum(name: name)
            }
        } catch {
            
        }
    }
    
    func removeThumbnail(albumID: UUID) {
        var albumIndex: AlbumIndex? = self.galleryManager.loadAlbumIndex(id: albumID)
        if var albumIndex {
            albumIndex.thumbnail = nil
            self.galleryManager.updateAlbumIndex(index: albumIndex)
        }
    }
    
    func deleteAlbum(id: UUID) {
        self.galleryManager.delete(album: id)
    }
    
    func getSelectedLibraryNameAsObservable() -> Observable<String> {
        self.settingsManager.selectedGalleryAsObservable
    }
}
