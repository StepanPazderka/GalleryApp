//
//  GallerySection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.03.2021.
//

import Foundation
import RealmSwift

struct AlbumIndex: Codable {
    var id: UUID = UUID()
    var name: String
    var images: [GalleryImage]
    var thumbnail: String?
    var thumbnailsSize: Float = 200
    var showingAnnotations: Bool? = false

    internal init(id: UUID = UUID() ,name: String, images: [GalleryImage], thumbnail: String, showingAnnotations: Bool? = false) {
        self.id = id
        self.name = name
        self.images = images
        self.thumbnail = thumbnail
        self.thumbnailsSize = 200
        self.showingAnnotations = showingAnnotations
    }

    init?(from entity: URL) {
        let albumIndexPath = entity.lastPathComponent == kAlbumIndex ? entity.relativePath : entity.appendingPathComponent(kAlbumIndex).relativePath

        guard let jsonData = try? String(contentsOfFile: albumIndexPath).data(using: .unicode) else {
            return nil
        }
    
        guard let decodedData = try? JSONDecoder().decode(AlbumIndex.self, from: jsonData) else {
            return nil
        }

        self.name = decodedData.name
        self.images = decodedData.images
        self.thumbnail = decodedData.thumbnail
        self.id = decodedData.id
        self.thumbnailsSize = decodedData.thumbnailsSize
        self.showingAnnotations = decodedData.showingAnnotations
    }
	
	init(from entity: AlbumIndexRealm) {
		self.id = UUID(uuidString: entity.id) ?? UUID()
		self.images = entity.images.map { GalleryImage(from: $0) }
		self.name = entity.name
		self.thumbnail = entity.thumbnail
		self.showingAnnotations = entity.showingAnnotations
		self.thumbnailsSize = entity.thumbnailSize
	}
    
    init(from entity: AlbumScreenModel) {
        self.id = entity.id
        self.name = entity.name
        self.images = entity.images
        self.thumbnail = entity.thumbnail
        self.thumbnailsSize = entity.thumbnailsSize
        self.showingAnnotations = entity.showingAnnotations
    }

    
    static var empty: Self {
        Self(name: "", images: [], thumbnail: "", showingAnnotations: false)
    }
}

// MARK: - Persistable Model Convertible conformity
extension AlbumIndex: PersistableModelConvertible {
	func toPersistableModel() -> AlbumIndexRealm {
		AlbumIndexRealm(from: self)
	}
}

