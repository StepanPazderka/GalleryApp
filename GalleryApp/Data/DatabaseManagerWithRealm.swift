//
//  DatabaseManagerImpl.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.04.2024.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import RxRealm

class DatabaseManagerWithRealm: DatabaseManager {
	let realm: Realm
	
	init() {
		self.realm = try! Realm()
	}
	
	func loadAlbum(id: UUID) throws -> Observable<AlbumIndex> {
		let albums = self.realm.objects(AlbumIndexRealm.self)
		
		if !albums.isEmpty {
			return Observable.from(object: albums).map { AlbumIndex(from: $0) }
		} else {
			
		}
	}
	
	func loadGalleryIndex(id: UUID) -> GalleryIndex {
		<#code#>
	}
	
	func loadGalleryIndex(name: String) -> GalleryIndex {
		<#code#>
	}
	
	
}
