//
//  SelectLibraryAnimatableSectionModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.04.2024.
//

import Foundation
import RxDataSources

struct SelectLibraryAnimatableSectionModel: AnimatableSectionModelType {
	let name: String
	let items: [GalleryIndex]
	
	init(name: String, items: [GalleryIndex]) {
		self.name = name
		self.items = items
	}
	
	init(original: SelectLibraryAnimatableSectionModel, items: [GalleryIndex]) {
		self.name = original.name
		self.items = items
	}
	
	var identity: String {
		return name
	}
}
