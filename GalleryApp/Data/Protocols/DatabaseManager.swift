//
//  DatabaseManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.04.2024.
//

import Foundation
import RxSwift

enum DatabaseManagerError {
	case cantFindAlbum
	case cantFindGalleryIndex
}

protocol DatabaseManager {
	func loadAlbum(id: UUID) throws -> Observable<AlbumIndex>
	func loadGalleryIndex(id: UUID) -> GalleryIndex
	func loadGalleryIndex(name: String) -> GalleryIndex
}
