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
    
    static func listImages() -> [String] {
        var outputImageList: [URL] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            print("Document Directory: \(documentDirectory)")
            
            for file in files {
                outputImageList.append(file)
            }
        } catch {
            print(error.localizedDescription)
        }

        return outputImageList.filter { $0.hasDirectoryPath == false }.map { $0.absoluteURL.lastPathComponent }
    }
    
    static func buildThumbs() {
        let images = listImages()
        for image in images {
            let newFilename = image
            let newImage = ImageResizer.resizeImage(image: UIImage(contentsOfFile: documentDirectory.appendingPathComponent(image).relativePath)!, targetSize: CGSize(width: 200, height: 200))
            if let jpegImage = newImage?.jpegData(compressionQuality: 1.0) {
                if FileManager.default.fileExists(atPath: documentDirectory.appendingPathComponent("thumbs").path) == false {
                    try? FileManager.default.createDirectory(atPath: documentDirectory.appendingPathComponent("thumbs").path, withIntermediateDirectories: false)
                }
                let filePath = documentDirectory.appendingPathComponent("thumbs").appendingPathComponent(newFilename)
                try? jpegImage.write(to: filePath)
            }
        }
    }
    
    static func writeThumb(image: UIImage) {
        
    }
    
    static func rebuildIndex(folder: URL) {
        let jsonTest = GalleryIndex(name: folder.lastPathComponent, images: self.listImages())
        buildThumbs()
        let json = try! JSONEncoder().encode(jsonTest)
        print(json)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    static func updateIndex(folder: URL, index: GalleryIndex) {
        let jsonTest = index
        
        let json = try! JSONEncoder().encode(jsonTest)
        print(json)
        let url = folder.appendingPathComponent("index.json")
        try? json.write(to: url)
    }
    
    static func loadIndex(folder: URL) -> GalleryIndex {
        if !FileManager.default.fileExists(atPath: folder.appendingPathComponent("index.json").relativePath) {
            rebuildIndex(folder: folder)
        }
        let jsonDATA = try! String(contentsOfFile: folder.appendingPathComponent("index.json").relativePath).data(using: .unicode)
        print("JSON Data: \(String(describing: jsonDATA))")
        let decodedData = try! JSONDecoder().decode(GalleryIndex.self, from: jsonDATA!)
        return decodedData
    }
}
