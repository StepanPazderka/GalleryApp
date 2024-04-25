//
//  AlbumScreenCollectionViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.04.2024.
//

import Foundation
import RxDataSources

struct AlbumScreenSectionModel {
	var name: String
	var items: [GalleryImage]
	
	init(items: [GalleryImage]) {
		self.name = "AlbumScreenSectionModel"
		self.items = items
	}
}

extension AlbumScreenSectionModel: AnimatableSectionModelType {
	init(original: AlbumScreenSectionModel, items: [GalleryImage]) {
		self.name = original.name
		self.items = items
	}
	
	var identity: String {
		return name
	}
}

extension AlbumScreenSectionModel: Equatable {
	public static func == (lhs: AlbumScreenSectionModel, rhs: AlbumScreenSectionModel) -> Bool {
		return lhs.items == rhs.items
	}
}
