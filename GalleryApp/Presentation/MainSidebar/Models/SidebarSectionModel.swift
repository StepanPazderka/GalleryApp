//
//  SidebarSection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 11.03.2023.
//

import Foundation
import RxDataSources

enum SidebarSectionModelType {
	case mainButtons
	case albumButtons
	case unknown
}

/// Struct representing Sidebar Section
struct SidebarSectionModel {
	var name: String
	var items: [SidebarItem]
	let type: SidebarSectionModelType
	
	init(type: SidebarSectionModelType, name: String, items: [SidebarItem]) {
		self.type = type
        self.name = name
        self.items = items
    }
    
    static var empty: Self {
		Self(type: .unknown, name: "None", items: [SidebarItem]())
    }
}

extension SidebarSectionModel: AnimatableSectionModelType {
    init(original: SidebarSectionModel, items: [SidebarItem]) {
        self.name = original.name
        self.items = items
		self.type = .unknown
    }
    
    var identity: String {
        return name
    }
}

extension SidebarSectionModel: Equatable {
    
}
