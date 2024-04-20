//
//  BehaviourSubject+toggle.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.04.2024.
//

import Foundation
import RxCocoa

extension BehaviorRelay where Element == Bool {
	func toggle() {
		self.accept(!value)
	}
}
