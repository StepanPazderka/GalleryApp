//
//  GallerySection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.03.2021.
//

import Foundation

struct AlbumIndex: Codable {
    var id: UUID = UUID()
    var name: String
    var images: [AlbumImage]
    var thumbnail: String
    var thumbnailsSize: Float = 200

    internal init(id: UUID = UUID() ,name: String, images: [AlbumImage], thumbnail: String) {
        self.id = id
        self.name = name
        self.images = images
        self.thumbnail = thumbnail
        self.thumbnailsSize = 200
    }

    init?(from entity: URL) {
        let indexPath = entity.lastPathComponent == kAlbumIndex ? entity.relativePath : entity.appendingPathComponent(kAlbumIndex).relativePath
        
        let jsonDATA = try? String(contentsOfFile: indexPath).data(using: .unicode)
        if let jsonData = jsonDATA {
            let decodedData = try? JSONDecoder().decode(AlbumIndex.self, from: jsonData)
            if let album = decodedData {
                self.name = album.name
                self.images = album.images
                self.thumbnail = album.thumbnail
                self.id = album.id
                self.thumbnailsSize = album.thumbnailsSize
                return 
            }
        }
        
        return nil
    }
    
    static var empty: Self {
        Self(name: "", images: [], thumbnail: "")
    }
}
