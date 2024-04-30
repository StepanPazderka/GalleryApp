//
//  PersistanceRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.04.2024.
//

import Foundation
import Realm
import RealmSwift

class PersistanceManagerWithRealm<PersistanceModel: Object>: PersistanceManager {
	
	// MARK: - Properties
	let realm: Realm
	
	// MARK: - Init
	init() throws {
		try self.realm = Realm()
	}
	
	// MARK: - CRUD
	func save(_ objectsToPersist: PersistanceModel) throws {
		do {
			try realm.write {
				realm.add(objectsToPersist, update: .modified)
			}
		} catch let error {
			throw error
		}
	}
	
	func load() throws -> [PersistanceModel] {
		let fetchedObjects = realm.objects(PersistanceModel.self)
		return Array(fetchedObjects)
	}
	
	func delete(_ objectsForDeletion: [PersistanceModel]) {
		realm.delete(objectsForDeletion)
	}
}
