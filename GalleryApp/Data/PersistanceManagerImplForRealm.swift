//
//  PersistanceRealm.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.04.2024.
//

import Foundation
import Realm
import RealmSwift

class PersistanceManagerWithRealm<AssociatedPersistableType: Object>: PersistanceManager {
	
	// MARK: - Properties
	let realm: Realm
	
	// MARK: - Init
	init() throws {
		try self.realm = Realm()
	}
	
	// MARK: - CRUD
	func save(_ objectsToPersist: [any PersistableModelConvertible]) throws {
		do {
			if let castedObjects = (objectsToPersist.map { $0.toPersistableModel() } as? [AssociatedPersistableType]) {
				try realm.write { [weak self] in
					self?.realm.add(castedObjects)
				}
			}
		} catch let error {
			throw error
		}
	}
	
	func save(_ objectToPersist: any PersistableModelConvertible) throws {
		do {
			if let castedObjects = (objectToPersist.toPersistableModel() as? AssociatedPersistableType) {
				try realm.write { [weak self] in
					self?.realm.add(castedObjects)
				}
			}
		} catch let error {
			throw error
		}
	}
	
	func load(_ object: any PersistableModelConvertible) throws -> AssociatedPersistableType {
		var returnArray = [AssociatedPersistableType]()
		var returnObject: AssociatedPersistableType!
		
		if let castedFirstObject = object.toPersistableModel() as? AssociatedPersistableType.Type {
			if let loadedObject = realm.objects(castedFirstObject).first {
				returnObject = loadedObject
			}
		}
		
		return returnObject
	}
	
	func update(_ objectsToPersist: [any PersistableModelConvertible]) throws {
		do {
			if let castedObjects = (objectsToPersist.map { $0.toPersistableModel() } as? [AssociatedPersistableType]) {
				try realm.write { [weak self] in
					self?.realm.add(castedObjects, update: .all)
				}
			}
		} catch let error {
			throw error
		}
	}
	
	func update(_ objectToPersist: any PersistableModelConvertible) throws {
		do {
			if let castedObjects = (objectToPersist.toPersistableModel() as? AssociatedPersistableType) {
				try realm.write { [weak self] in
					self?.realm.add(castedObjects, update: .all)
				}
			}
		} catch let error {
			throw error
		}
	}
	
	func delete(_ objectsForDeletion: [any PersistableModelConvertible]) {
		if let castedObjects = (objectsForDeletion.map { $0.toPersistableModel() } as? AssociatedPersistableType) {
			realm.delete(castedObjects)
		}
	}
}
