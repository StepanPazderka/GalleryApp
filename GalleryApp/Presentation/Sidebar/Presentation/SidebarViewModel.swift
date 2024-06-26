//
//  MainSideBarViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.12.2021.
//

import Foundation
import RxSwift
import RxCocoa
import LocalAuthentication

class SidebarViewModel {
	
	// MARK: -- Properties
	private let galleryManager: GalleryManager
	private let settingsManager: SettingsManagerImpl
	private let pathResolver: PathResolver
	
	private let localAuthnentication = LAContext()
	
	var errorMessage = BehaviorRelay(value: "")
	
	let disposeBag = DisposeBag()
	
	let mainButonsSection = SidebarSectionModel(type: .mainButtons, name: NSLocalizedString("kMAIN", comment: "Main buttons"), items: [
		SidebarItemModel(title: NSLocalizedString("kALLPHOTOS", comment: "Title for sidebar cell to show All Photos in library"), image: nil, buttonType: .allPhotos)
	])
	
	init(galleryInteractor: GalleryManager, settingsManager: SettingsManagerImpl, pathResolver: PathResolver) {
		self.galleryManager = galleryInteractor
		self.settingsManager = settingsManager
		self.pathResolver = pathResolver
	}
	
	func renameAlbum(id: UUID, withNewAlbumName: String) throws {
		do {
			if var albumIndex = self.galleryManager.loadAlbumIndex(with: id) {
				albumIndex.name = withNewAlbumName
				try self.galleryManager.updateAlbumIndex(index: albumIndex)
			}
		} catch {
			self.errorMessage.accept(error.localizedDescription)
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
				let albumObservables = galleryIndex.albums.compactMap { albumID -> Observable<SidebarItemModel?> in
					self.galleryManager.loadAlbumIndexAsObservable(id: albumID)
						.map { [unowned self] albumIndex -> SidebarItemModel? in
							var thumbnailImage: UIImage?
							if albumIndex.locked {
								thumbnailImage = UIImage(systemName: "lock")
							} else if let thumbnailFileName = albumIndex.thumbnail, !thumbnailFileName.isEmpty {
								let thumbnailPath = self.pathResolver.selectedGalleryPath.appendingPathComponent(thumbnailFileName)
								thumbnailImage = UIImage(contentsOfFile: thumbnailPath.relativePath)
							} else {
								if let thumbnailFileName = albumIndex.images.first?.fileName {
									let thumbnailPath = self.pathResolver.selectedGalleryPath.appendingPathComponent(thumbnailFileName)
									thumbnailImage = UIImage(contentsOfFile: thumbnailPath.relativePath)
								}
							}
							
							return SidebarItemModel(
								id: UUID(uuidString: albumIndex.id.uuidString),
								locked: albumIndex.locked,
								title: albumIndex.name,
								image: thumbnailImage,
								buttonType: .album
							)
						}
						.catchAndReturn(nil)
				}
				
				return Observable.combineLatest(albumObservables)
					.map { albumItems in
						let albumButtons = SidebarSectionModel(type: .albumButtons, name: NSLocalizedString("kALBUMS", comment: ""), items: albumItems.compactMap { $0 })
						return [self.mainButonsSection, albumButtons]
					}
			}
	}
	
	func lockAlbum(albumID: UUID) {
		do {
			if var albumIndex = self.galleryManager.loadAlbumIndex(with: albumID) {
				albumIndex.locked = true
				try self.galleryManager.updateAlbumIndex(index: albumIndex)
			}
		} catch {
			self.errorMessage.accept(error.localizedDescription)
		}
	}
	
	func unlockAlbum(albumID: UUID) {
		do {
			if var albumIndex = self.galleryManager.loadAlbumIndex(with: albumID) {
				albumIndex.locked = false
				try self.galleryManager.updateAlbumIndex(index: albumIndex)
			}
		} catch {
			self.errorMessage.accept(error.localizedDescription)
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
			self.errorMessage.accept(error.localizedDescription)
		}
	}
	
	func removeThumbnail(albumID: UUID) {
		do {
			if var albumIndex = self.galleryManager.loadAlbumIndex(with: albumID) {
				albumIndex.thumbnail = nil
				try self.galleryManager.updateAlbumIndex(index: albumIndex)
			}
		} catch {
			self.errorMessage.accept(error.localizedDescription)
		}
	}
	
	func deleteAlbum(id: UUID) {
		do {
			try self.galleryManager.delete(album: id)
		} catch {
			self.errorMessage.accept(error.localizedDescription)
		}
	}
	
	func getSelectedLibraryNameAsObservable() -> Observable<String> {
		self.settingsManager.getCurrentlySelectedGalleryIDAsObservable()
			.catch { [weak self] error -> Observable<String> in
				if let returnID = self?.galleryManager.loadGalleriesAsObservable().compactMap({ $0.first?.id }).compactMap ({ $0.uuidString }) {
					return returnID
				} else {
					return .empty()
				}
			}
			.flatMapLatest { [weak self] galleryID -> Observable<String> in
				guard let self = self else { return .empty() }
				return self.galleryManager.loadGalleriesAsObservable()
					.compactMap { [weak self] galleries -> String? in
						if let returnValue = galleries.first(where: { $0.id.uuidString == galleryID })?.mainGalleryName {
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
	
	func authenticateUser(completion: @escaping (() -> Void)) {
		self.localAuthnentication.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("kUnlockAlbum", comment: ""), reply: { [weak self] succeeded, error in
			if succeeded {
				completion()
			}
			
			if let error {
				switch error {
				case LAError.biometryNotAvailable:
					self?.errorMessage.accept(NSLocalizedString("kBiometryNotAvailable", comment: ""))
				case LAError.biometryNotEnrolled:
					self?.errorMessage.accept(NSLocalizedString("kBiometryNotSetup", comment: ""))
				default:
					self?.errorMessage.accept(NSLocalizedString("kAuthenticationGeneralError", comment: ""))
				}
			}
		})
	}
	
	func canAuthenticate() -> Bool {
		var nsError: NSError?
		if localAuthnentication.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError) {
			return true
		} else {
			if let error = nsError?.localizedDescription {
				errorMessage.accept(error)
			}
			return false
		}
	}
}
