//
//  GalleryAppTests.swift
//  GalleryAppTests
//
//  Created by Štěpán Pazderka on 23.10.2022.
//

import XCTest

@testable import GalleryApp
final class GalleryAppTests: XCTestCase {
    func testAlbumCreation() {
        let uS = UnsecureStorage()
        let sM = SettingsManagerImpl(unsecureStorage: uS)
        let fSM = FileScannerManager(settings: sM)
        let pathResolver = PathResolver(settingsManager: sM)
        
        let galleryManager = GalleryManagerImpl(settingsManager: sM, fileScannerManger: fSM, pathResolver: pathResolver, isTesting: true)
        var newTestAlbum: AlbumIndex?
        do {
            newTestAlbum = try galleryManager.createAlbum(name: "Test", parentAlbum: nil)
        } catch {
            print("")
        }
        guard let newTestAlbum else { return }
        
        let testAlbumRead = galleryManager.loadAlbumIndex(id: newTestAlbum.id)
        XCTAssert(testAlbumRead?.name == "Test")
    }
    
    func testGalleryManager() throws {
        let uS = UnsecureStorage()
        let sM = SettingsManagerImpl(unsecureStorage: uS)
        let fSM = FileScannerManager(settings: sM)
        let pathResolver = PathResolver(settingsManager: sM)
        
        self.measure {
            let l = GalleryManagerImpl(settingsManager: sM, fileScannerManger: fSM, pathResolver: pathResolver, isTesting: true)
        }
    }
}
