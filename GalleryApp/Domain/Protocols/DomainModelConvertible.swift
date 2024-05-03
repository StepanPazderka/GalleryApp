//
//  DomainModelConvertible.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.04.2024.
//

import Foundation
import RealmSwift

protocol DomainModelConvertible {
	associatedtype DomainModelType
	
	func toDomainModel() -> DomainModelType
}
