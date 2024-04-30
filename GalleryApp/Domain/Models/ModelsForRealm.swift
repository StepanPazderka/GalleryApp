//
//  GalleryIndexRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 03.11.2023.
//

import Foundation
import Realm
import RealmSwift

final class GalleryImageRealm: Object, ObjectKeyIdentifiable {
	@Persisted var id: String = UUID().uuidString
	@Persisted var fileName: String
	@Persisted var date: Date
	@Persisted var title: String?
	@Persisted var parentGallery = LinkingObjects(fromType: GalleryIndexRealm.self, property: "images")
	
	override static func primaryKey() -> String? {
		return "id"
	}
	
	required override init() {
		super.init()
	}
	
	init(id: String = UUID().uuidString, fileName: String, date: Date, title: String? = nil) {
		self.id = id
		self.fileName = fileName
		self.date = date
		self.title = title
	}
	
	init(from entity: GalleryImage) {
		super.init()
		self.id = entity.id.uuidString
		self.fileName = entity.fileName
		self.date = entity.date
		self.title = entity.title
		self.id = entity.id.uuidString
	}
}

final class AlbumIndexRealm: Object, ObjectKeyIdentifiable {
	@Persisted var id: String = UUID().uuidString
	@Persisted var name: String
	@Persisted var thumbnail: String
	@Persisted var showingAnnotations: Bool = false
	@Persisted var thumbnailSize: Float = 200
	@Persisted var images = RealmSwift.List<GalleryImageRealm>()
	@Persisted var parentGalleryIndex = LinkingObjects(fromType: GalleryIndexRealm.self, property: "albums")
	
	override static func primaryKey() -> String? {
		return "id"
	}
	
	required override init() {
		super.init()
	}
	
	init(id: String = UUID().uuidString, name: String, thumbnail: String, showingAnnotations: Bool = false, thumbnailSize: Float = 200, images: RealmSwift.List<GalleryImageRealm> = RealmSwift.List<GalleryImageRealm>()) {
		self.id = id
		self.name = name
		self.thumbnail = thumbnail
		self.showingAnnotations = showingAnnotations
		self.thumbnailSize = thumbnailSize
		self.images = images
	}
	
	init(from entity: AlbumIndex) {
		super.init()
		self.id = entity.id.uuidString
		self.name = entity.name
		self.thumbnail = entity.thumbnail ?? String()
		self.showingAnnotations = entity.showingAnnotations ?? false
		self.thumbnailSize = entity.thumbnailsSize
		entity.images.forEach { [weak self] galleryImage in
			self?.images.append(GalleryImageRealm(from: galleryImage))
		}
	}
	
	convenience init(name: String) {
		self.init()
		self.id = UUID().uuidString
		self.name = name
	}
}

final class GalleryIndexRealm: Object, ObjectKeyIdentifiable {
	@Persisted var id: String = UUID().uuidString
	@Persisted var name: String = ""
	@Persisted var thumbnailSize: Float = 200
	@Persisted var showingAnnotations: Bool = false
	@Persisted var albums = RealmSwift.List<AlbumIndexRealm>()
	@Persisted var images = RealmSwift.List<GalleryImageRealm>()
	
	override static func primaryKey() -> String? {
		return "id"
	}
	
	required override init() {
		super.init()
	}
	
	convenience init(name: String, thumbnailSize: Float, showingAnnotations: Bool) {
		self.init()
		self.name = name
		self.thumbnailSize = thumbnailSize
		self.showingAnnotations = showingAnnotations
	}
	
	init(id: String = UUID().uuidString, name: String = "", thumbnailSize: Float = 200, showingAnnotations: Bool = false, albums: RealmSwift.List<AlbumIndexRealm> = RealmSwift.List<AlbumIndexRealm>(), images: RealmSwift.List<GalleryImageRealm> = RealmSwift.List<GalleryImageRealm>()) {
		self.id = id
		self.name = name
		self.thumbnailSize = thumbnailSize
		self.showingAnnotations = showingAnnotations
		self.albums = albums
		self.images = images
	}
	
	init(from entity: GalleryIndex) {
		super.init()
		self.id = entity.id.uuidString
		self.name = entity.mainGalleryName
		self.showingAnnotations = entity.showingAnnotations ?? false
		self.thumbnailSize = entity.thumbnailSize ?? 200
		
		entity.images.forEach { [weak self] galleryImage in
			self?.images.append(GalleryImageRealm(from: galleryImage))
		}
		
		let remmapedAlbums = entity.albums.map { albumID in
			let realm = try! Realm()
			
			let fetchedAlbum = realm.objects(AlbumIndexRealm.self).filter("id == %@", albumID.uuidString).first
			
			return fetchedAlbum
		}.compacted()
		
		for album in remmapedAlbums {
			self.albums.append(album)
		}
	}
}
