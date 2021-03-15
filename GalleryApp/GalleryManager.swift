//
//  GalleryManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 18.01.2021.
//

import Foundation
import UIKit

class GalleryManager {
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static func loadImage() -> UIImage {
        var outputImage: UIImage = UIImage()
        return outputImage
    }
    
    static func listImages() -> [URL] {
        var outputImageList: [URL] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            print("Document Directory: \(documentDirectory)")
            
            for file in files {
                outputImageList.append(file)
            }
        } catch {
            print(error.localizedDescription)
        }

        return outputImageList
    }
    
    static func rebuildIndex(folder: URL) {
        let jsonTest = GalleryFolder(name: folder.lastPathComponent, images: self.listImages())
        
        let json = try! JSONEncoder().encode(jsonTest)
        print(json)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    static func saveNewIndex(folder: URL, index: GalleryFolder) {
        let jsonTest = index
        
        let json = try! JSONEncoder().encode(jsonTest)
        print(json)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    static func loadIndex(folder: URL) -> GalleryFolder {
        if !FileManager.default.fileExists(atPath: folder.appendingPathComponent("index.json").relativePath) {
            rebuildIndex(folder: folder)
        }
        let jsonDATA = try! String(contentsOfFile: folder.appendingPathComponent("index.json").relativePath).data(using: .utf8)
        print("JSON Data: \(String(describing: jsonDATA))")
        let json = try! JSONDecoder().decode(GalleryFolder.self, from: jsonDATA!)
        return json
    }
}
