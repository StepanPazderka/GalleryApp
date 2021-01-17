//
//  InsertImage.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.12.2020.
//

import UIKit
import UniformTypeIdentifiers

class InsertImage: UIViewController, UIDocumentPickerDelegate {

    var documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel(frame: CGRect(x: 400, y: 500, width: 100, height: 100))
        label.text = "Test text"
        view.addSubview(label)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let allowedTypes: [UTType] = [UTType.image]
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        documentPicker.shouldShowFileExtensions = true
        
        self.present(documentPicker, animated: true)
        print("Document Directory is at: \(documentDirectory)")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            do {
                try FileManager().moveItem(at: url, to: documentDirectory.first!.appendingPathComponent(url.lastPathComponent))
                print("Copied to \(url)")
                print("Document directory \(documentDirectory.first!)")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
