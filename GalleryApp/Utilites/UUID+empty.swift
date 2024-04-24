//
//  UUID+empty.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 19.11.2023.
//

import Foundation

extension UUID {
    static var empty = Self(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
}
