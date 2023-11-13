//
//  GalleryIndexRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 03.11.2023.
//

import Foundation
import Realm
import RealmSwift

class GalleryImageRealm: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var fileName: String
    @Persisted var date: Date
    @Persisted var title: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    init(from entity: GalleryImage) {
        self.fileName = entity.fileName
        self.date = entity.date
        self.title = entity.title
        self.id = entity.id.uuidString
    }
}

class AlbumIndexRealm: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String
    @Persisted var thumbnail: String
    @Persisted var showingAnnotations: Bool = false
    @Persisted var thumbnailSize: Float = 200
    var images = List<GalleryImageRealm>()
    
    override static func primaryKey() -> String? {
        return "id"
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
}

class GalleryIndexRealm: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String = ""
    @Persisted var thumbnailSize: Float = 200
    @Persisted var showingAnnotations: Bool = false
    var albums = List<AlbumIndexRealm>()
    var images = List<GalleryImageRealm>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(name: String, thumbnailSize: Float, showingAnnotations: Bool) {
        self.init()
        self.name = name
        self.thumbnailSize = thumbnailSize
        self.showingAnnotations = showingAnnotations
    }
    
    init(from entity: GalleryIndex) {
        super.init()
        self.name = entity.mainGalleryName
        self.showingAnnotations = entity.showingAnnotations ?? false
        self.thumbnailSize = entity.thumbnailSize ?? 200
        
        entity.images.forEach { [weak self] galleryImage in
            self?.images.append(GalleryImageRealm(from: galleryImage))
        }
        
//        self.images = entity.images.map { GalleryImageRealm(from: $0) }
    }
}
