//
//  DocumentPicker.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.01.2021.
//

import Foundation
import SwiftUI
import MobileCoreServices

/// A wrapper for a UIDocumentPickerViewController that acts as a delegate and passes the selected file to a callback
///
/// DocumentPicker also sets allowsMultipleSelection to `false`.
final class DocumentPicker: NSObject {

    /// The types of documents to show in the picker
    let types: [String]

    /// The callback to call with the selected document URLs
    let callback: ([URL]) -> ()

    /// Should the user be allowed to select more than one item?
    let allowsMultipleSelection: Bool

    /// Creates a DocumentPicker, defaulting to selecting folders and allowing only one selection
    init(for types: [String] = [String(kUTTypeFolder)],
         allowsMultipleSelection: Bool = false,
         _ callback: @escaping ([URL]) -> () = { _ in }) {
        self.types = types
        self.allowsMultipleSelection = allowsMultipleSelection
        self.callback = callback
    }

    /// Returns the view controller that must be presented to display the picker
    lazy var viewController: UIDocumentPickerViewController = {
        let vc = UIDocumentPickerViewController(documentTypes: types, in: .open)
        vc.delegate = self
        vc.allowsMultipleSelection = self.allowsMultipleSelection
        return vc
    }()

}

extension DocumentPicker: UIDocumentPickerDelegate {
    /// Delegate method that's called when the user selects one or more documents or folders
    ///
    /// This method calls the provided callback with the URLs of the selected documents or folders.
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        callback(urls)
    }

    /// Delegate method that's called when the user cancels or otherwise dismisses the picker
    ///
    /// Does nothing but close the picker.
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
        print("cancelled")
    }
}
