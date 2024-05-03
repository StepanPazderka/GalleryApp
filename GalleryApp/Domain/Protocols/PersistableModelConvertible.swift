//
//  PersistableModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.04.2024.
//

import Foundation

protocol PersistableModelConvertible {
	associatedtype PersistableType
	
	func toPersistableModel() -> PersistableType
}
