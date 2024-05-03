//
//  GalleryManagerRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 05.11.2023.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import RxRealm
import UniformTypeIdentifiers

class GalleryManagerImpl: GalleryManager {
	// MARK: - Protocol Properties
	internal let settingsManager: SettingsManager
	private let pathResolver: PathResolver
	
	// MARK: - Custom Properties
	private let realm: Realm?
	private let disposeBag: DisposeBag = DisposeBag()
		
	// MARK: - Init
	init(settingsManager: SettingsManagerImpl, pathResolver: PathResolver) {
		self.settingsManager = settingsManager
		self.pathResolver = pathResolver
				
		do {
			self.realm = try Realm()
		} catch {
			print("Error: \(error)")
			self.realm = nil
		}
		
		Observable.combineLatest(getCurrentlySelectedGalleryIDAsObservable(), loadGalleriesAsObservable()).subscribe(onNext: { [weak self] (selectedID, galleries) in
			guard let self else { return }
			let staticGalleries = self.loadGalleries()
			
			var totalGalleries = [GalleryIndex]()
			totalGalleries.append(contentsOf: staticGalleries)
			totalGalleries.append(contentsOf: galleries)
			
			func createNewDefaultGallery() {
				if let newGallery = try? self.createGalleryIndex(name: NSLocalizedString("kDEFAULTLIBRARY", comment: "Defaut library")) {
					self.settingsManager.set(key: .selectedGallery, value: newGallery.id.uuidString)
				}
			}

			if totalGalleries.isEmpty {
				createNewDefaultGallery()
			}
		}).disposed(by: disposeBag)
	}
	
	// MARK: - Create
	func add(images: [GalleryImage], toAlbum album: AlbumIndex? = nil) {
		let galleryImagesForRealm = images.map { GalleryImageRealm(from: $0) }
		
		do {
			try realm?.write {
				if let index = load() {
					let indexForRealm = GalleryIndexRealm(from: index)
					indexForRealm.images.append(objectsIn: galleryImagesForRealm)
					realm?.add(indexForRealm, update: .modified)
					
					if let album {
						if let albumIndex = loadAlbumIndex(with: album.id) {
							let albumIndexRealm = AlbumIndexRealm(from: albumIndex)
							albumIndexRealm.images.append(objectsIn: galleryImagesForRealm)
							realm?.add(albumIndexRealm, update: .modified)
						}
					}
				}
				
				realm?.add(galleryImagesForRealm)
			}
		} catch {
			print(error)
		}
	}
	
	@discardableResult
	func createAlbum(name: String, parentAlbum: UUID?) throws -> AlbumIndex {
		let newAlbumIndex = AlbumIndexRealm(name: name)
		
		var galleryIndex = load()
		galleryIndex?.albums.append(AlbumIndex(from: newAlbumIndex).id)
		
		try! realm?.write {
			if let galleryIndex {
				let galleryRealmInstance = GalleryIndexRealm(from: galleryIndex)
				galleryRealmInstance.albums.append(newAlbumIndex)
				
				realm?.add(newAlbumIndex)
				realm?.add(galleryRealmInstance, update: .modified)
			}
		}
		
		return AlbumIndex(from: newAlbumIndex)
	}
	
	func loadImageAsObservable(with id: UUID) -> Observable<GalleryImage> {
		let results = realm?.objects(GalleryImageRealm.self).first {
			$0.id == id.uuidString
		}
		
		if let results {
			return Observable.from(object: results).map { GalleryImage(from: $0) }
		} else {
			return Observable.just(.empty)
		}
	}
	
	func loadAlbumIndex(with id: UUID) -> AlbumIndex? {
		realm?.objects(AlbumIndexRealm.self).first { albumIndex in
			albumIndex.id == id.uuidString
		}.map { AlbumIndex(from: $0) }
	}
	
	func load(galleryIndex: String? = nil) -> GalleryIndex? {
		var fetchedIndex: GalleryIndex?
		
		if let fetchedGalleryIndeces = self.realm?.objects(GalleryIndexRealm.self).first(where: { galleryIndex in
			galleryIndex.id == self.settingsManager.getSelectedLibraryName()
		}) {
			return GalleryIndex(from: fetchedGalleryIndeces)
		}
		
		fetchedIndex = self.realm?.objects(GalleryIndexRealm.self).map { GalleryIndex(from: $0) }.first(where: { [weak self] in
			$0.id.uuidString == self?.settingsManager.getSelectedLibraryName()
		})
		
		return fetchedIndex
	}
	
	func loadAlbumIndexAsObservable(id: UUID) -> Observable<AlbumIndex> {
		let results = realm?.objects(AlbumIndexRealm.self).first {
			$0.id == id.uuidString
		}
		
		if let results {
			return Observable.from(object: results).map { AlbumIndex(from: $0) }
		} else {
			return Observable.empty()
		}
	}
	
	@discardableResult 
	func createGalleryIndex(name: String) throws -> GalleryIndex {
		guard let realm = realm else {
			throw GalleryManagerError.unknown
		}
		
		return try realm.write {
			let newGalleryIndex = GalleryIndexRealm(name: name, thumbnailSize: 200, showingAnnotations: false)
			realm.add(newGalleryIndex)
			
			return GalleryIndex(from: newGalleryIndex)
		}
	}
	
	func delete(images: [GalleryImage]) {
		guard let realm = realm else { return }
		
		let imageIDs = images.map { $0.id.uuidString }
		
		do {
			try realm.write {
				let imagesToDelete = realm.objects(GalleryImageRealm.self).filter("id IN %@", imageIDs)
				realm.delete(imagesToDelete)
				for image in images {
					let fullImagePath = self.pathResolver.resolvePathFor(imageName: image.fileName)
					let thumbImagePath = self.pathResolver.resolveThumbPathFor(imageName: image.fileName)
					
					let paths = [fullImagePath, thumbImagePath]
					
					for path in paths {
						try? FileManager.default.removeItem(atPath: path)
					}
				}
			}
		} catch {
			print("Error deleting images: \(error)")
		}
	}

	func load<DatabaseObject: Object>(_ type: DatabaseObject.Type) -> Observable<[DatabaseObject]> {
		if let objects = realm?.objects(type) {
			return Observable.collection(from: objects).map { Array($0) }
		} else {
			return Observable.empty()
		}
	}
	
	func loadGalleries() -> [GalleryIndex] {
		guard let galleries = realm?.objects(GalleryIndexRealm.self) else { return [GalleryIndex]() }
		return galleries.map { GalleryIndex(from: $0) }
	}
	
	func loadGalleriesAsObservable() -> Observable<[GalleryIndex]> {
		if let indeces = realm?.objects(GalleryIndexRealm.self) {
			return Observable.collection(from: indeces)
				.map { results in
					results.filter { !$0.isInvalidated }
						.map { GalleryIndex(from: $0) }
				}
		} else {
			return .empty()
		}
	}
	
	func updateGalleryIndex(newGalleryIndex: GalleryIndex) -> GalleryIndex {
		let newGalleryIndexRealm = GalleryIndexRealm(from: newGalleryIndex)
		
		try! realm?.write {
			realm?.add(newGalleryIndexRealm, update: .modified)
		}
		
		return newGalleryIndex
	}
	
	func buildThumbnail(forImage albumImage: GalleryImage) {
		let images = self.load()?.images
		
		let thumbPath = pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(albumImage.fileName).deletingPathExtension().appendingPathExtension(for: .jpeg)
		
		guard !FileManager.default.fileExists(atPath: thumbPath.relativePath) else { return }
		
		guard images != nil else { return }
		
		let image = UIImage(contentsOfFile: pathResolver.selectedGalleryPath.appendingPathComponent(albumImage.fileName).relativePath)
		
		guard let image else { return }
		let resizedImage = ImageResizer.resizeImage(image: image, targetSize: CGSize(width: 300, height: 300))
		guard let resizedImage else { return }
		let jpegImage = resizedImage.jpegData(compressionQuality: 0.6)
		if !FileManager.default.fileExists(atPath: pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs).relativePath) {
			try? FileManager.default.createDirectory(at: pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs), withIntermediateDirectories: false)
		}
		
		try? jpegImage?.write(to: thumbPath)
	}
	
	func deleteGallery(named galleryName: String) {
		guard let realm = realm, let galleryToDelete = realm.objects(GalleryIndexRealm.self).first(where: { $0.name == galleryName }) else { return }
		
		let galleryURL = pathResolver.resolveDocumentsPath().appendingPathComponent(galleryToDelete.id, conformingTo: UTType.folder)
		if FileManager.default.fileExists(atPath: galleryURL.relativePath) {
			try? FileManager.default.removeItem(at: galleryURL)
		}
		
		try? realm.write {
			realm.delete(galleryToDelete)
			
		}
	}
	
	@discardableResult func duplicate(album: AlbumIndex) -> AlbumIndex {
		guard let fetchedAlbum = realm?.objects(AlbumIndexRealm.self).first(where: { $0.id == album.id.uuidString }) else { return album }
		
		let newAlbum = AlbumIndexRealm(id: UUID().uuidString, name: fetchedAlbum.name, thumbnail: fetchedAlbum.thumbnail, images: fetchedAlbum.images)
		
		if let index = load() {
			try! realm?.write {
				let updatedIndex = GalleryIndexRealm(from: index)
				updatedIndex.albums.append(newAlbum)
				realm?.add(updatedIndex, update: .modified)
				
				realm?.add(newAlbum)
			}
		}
		
		return AlbumIndex(from: newAlbum)
	}
	
	func update(image: GalleryImage) {
		let newGalleryImageRealm = GalleryImageRealm(from: image)
		
		do {
			try realm?.write {
				realm?.add(newGalleryImageRealm, update: .all)
			}
		} catch {
			print("Some error while trying to persist data: \(error)")
		}
	}
	
	func resolveThumbPathFor(imageName: String) -> String {
		return self.pathResolver.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(imageName).deletingPathExtension().appendingPathExtension(for: .jpeg).relativePath
	}
	
	func resolvePathFor(imageName: String) -> String {
		return self.pathResolver.selectedGalleryPath.appendingPathComponent(imageName, conformingTo: .image).relativePath
	}
	
	func remove(image: GalleryImage, from album: AlbumIndex) {
		let imageForRealm = GalleryImageRealm(from: image)
		let albumIndexRealm = AlbumIndexRealm(from: album)
		let index = albumIndexRealm.images.firstIndex(where: { $0 == imageForRealm })
		if let index {
			albumIndexRealm.images.remove(at: index)
			
			try! realm?.write {
				realm?.add(albumIndexRealm, update: .modified)
			}
		}
	}
	
	func removeAlbum(AlbumName: String) {
		do {
			try FileManager.default.removeItem(atPath: pathResolver.selectedGalleryPath.appendingPathComponent(AlbumName).path)
		} catch {
			print("Error while removing album: \(error)")
		}
	}
	
	func delete(album: UUID) {
		let albumForDeletion = realm?.objects(AlbumIndexRealm.self).filter("id == %@", album.uuidString)
		
		if let albumForDeletion {
			try! realm?.write {
				realm?.delete(albumForDeletion)
			}
		}
	}
	
	func duplicate(images: [GalleryImage], inAlbum album: AlbumIndex?) throws {
		let imagesForRealm = images.map { galleryImage in
			let imageForRealm = GalleryImageRealm(from: galleryImage)
			imageForRealm.id = UUID().uuidString
			return imageForRealm
		}
		
		if let index = load(galleryIndex: nil) {
			let indexForRealm = GalleryIndexRealm(from: index)
			indexForRealm.images.append(objectsIn: imagesForRealm)
			
			do {
				try realm?.write {
					
					if let album {
						let AlbumIndexRealm = AlbumIndexRealm(from: album)
						AlbumIndexRealm.images.append(objectsIn: imagesForRealm)
						realm?.add(AlbumIndexRealm)
					}
					
					realm?.add(imagesForRealm)
					realm?.add(indexForRealm, update: .modified)
				}
			} catch {
				throw error
			}
		}
	}
	
	func move(images: [GalleryImage], toAlbum: UUID, callback: (() -> ())?) throws {
		let album = self.loadAlbumIndex(with: toAlbum)
		if var album {
			for image in images {
				if !album.images.contains(image) {
					album.images.append(image)
				}
			}
			
			try? realm?.write {
				let albumIndexRealm = AlbumIndexRealm(from: album)
				realm?.add(albumIndexRealm, update: .modified)
			}
		}
	}
	
	@discardableResult 
	func updateAlbumIndex(index: AlbumIndex) throws -> AlbumIndex {
		do {
			try realm?.write {
				let updatedIndex = AlbumIndexRealm(from: index)
				
				realm?.add(updatedIndex, update: .modified)
			}
		} catch {
			throw error
		}
		
		if let updatedAlbumFromDatabse = realm?.objects(AlbumIndexRealm.self).filter("id == %@", index.id.uuidString).first {
			return AlbumIndex(from: updatedAlbumFromDatabse)
		} else {
			throw GalleryManagerError.cantReadAlbum
		}
	}
}

extension GalleryManagerImpl {
	func loadGalleryIndexAsObservable() -> Observable<GalleryIndex> {
		let selectedGalleryName = self.settingsManager.selectedGalleryName
				
		if let index = self.realm?.objects(GalleryIndexRealm.self).first(where: { galleryIndex in
			galleryIndex.name == selectedGalleryName
		}) {
			return Observable.from(object: index).map { GalleryIndex(from: $0) }
		} else {
			return .empty()
		}
	}
	
	func loadCurrentGalleryIndexAsObservable() -> Observable<GalleryIndex> {
		Observable.combineLatest(settingsManager.getCurrentlySelectedGalleryIDAsObservable(), self.loadGalleriesAsObservable())
			.map { [weak self] (currentlySelectedGalleryID, galleries) -> GalleryIndex in
				guard let self else { return .empty }
				let staticGalleries = loadGalleries()
				
				if let selectedGallery = staticGalleries.first(where: { $0.id.uuidString == currentlySelectedGalleryID }) {
					return selectedGallery
				} else if let firstGallery = galleries.first {
					self.settingsManager.set(key: .selectedGallery, value: firstGallery.id.uuidString)
					return firstGallery
				}
				return .empty
			}
	}
	
	func loadCurrentGalleryIndex() -> GalleryIndex? {
		self.load(galleryIndex: self.settingsManager.selectedGalleryName)
	}
	
	func getCurrentlySelectedGalleryIDAsObservable() -> Observable<String> {
		self.settingsManager.getCurrentlySelectedGalleryIDAsObservable()
	}
}
