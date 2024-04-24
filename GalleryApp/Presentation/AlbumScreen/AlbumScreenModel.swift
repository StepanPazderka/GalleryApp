//
//  AlbumScreenModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.11.2022.
//

import Foundation

struct AlbumScreenModel {
    var id: UUID
    var name: String
    var images: [GalleryImage]
    var thumbnail: String
    var thumbnailsSize: Float = 200
    var showingAnnotations: Bool
    
    internal init(id: UUID, name: String, images: [GalleryImage], thumbnail: String, thumbnailsSize: Float = 200, showingAnnotations: Bool) {
        self.id = id
        self.name = name
        self.images = images
        self.thumbnail = thumbnail
        self.thumbnailsSize = thumbnailsSize
        self.showingAnnotations = showingAnnotations
    }
    
    init(from: AlbumIndex) {
        self.id = from.id
        self.name = from.name
        self.images = from.images
        if let selectedThumbnailName = from.thumbnail {
            self.thumbnail = selectedThumbnailName
        } else {
            self.thumbnail = ""
        }
        self.thumbnailsSize = from.thumbnailsSize
        if let showingAnnotations = from.showingAnnotations {
            self.showingAnnotations = showingAnnotations
        } else {
            self.showingAnnotations = false
        }
    }
    
    init(from: GalleryIndex) {
        self.id = from.id
        self.name = from.mainGalleryName
        self.images = from.images
        self.thumbnail = ""
        if let thumbnailSize = from.thumbnailSize {
            self.thumbnailsSize = thumbnailSize
        } else {
            self.thumbnailsSize = 200
        }
        if let showingAnnotations = from.showingAnnotations {
            self.showingAnnotations = showingAnnotations
        } else {
            self.showingAnnotations = false
        }
    }
    
    static var empty: Self {
        Self(id: UUID(), name: "", images: [], thumbnail: "", showingAnnotations: false)
    }
}

extension AlbumScreenModel: Equatable {}
