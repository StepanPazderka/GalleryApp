//
//  EmptyViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit
import RxSwift
import RxCocoa
import UniformTypeIdentifiers
import simd

enum GallerySection: String {
    case main
}

struct GalleryItem: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()
}

class AlbumScreenViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ListsImages {
    var galleryManager: GalleryManager
    
    var screenView = AlbumScreenView()
    
    var albumName: String?
    
    var viewModel = AlbumScreenViewModel(albumName: "Test")
    
    var collectionView: UICollectionView?
    
    let cellName = "AlbumImageCell"
    
    let disposeBag = DisposeBag()

    public var listedImages: [AlbumImage] = []
        
    var editingRx = BehaviorRelay<Bool>(value: false)
    
    let doneButton: UIButton = { let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        return button
    }()
    
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        button.sizeToFit()
        return button
    }()
    
    let addImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
        button.sizeToFit()
        return button
    }()
    
    let imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.allowsEditing = false
        return view
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showDocumentPicker() {
        let allowedTypes: [UTType] = [UTType.image]

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        self.present(documentPicker, animated: true)
    }
    
    func showImagePicker() {
        imagePicker.delegate = self
        self.present(self.imagePicker, animated: true)
    }
    
    init(galleryInteractor: GalleryManager, albumName: String? = nil) {
        if let albumName = albumName {
            self.albumName = albumName
        }
        self.galleryManager = galleryInteractor
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        
        if let albumName = albumName {
            galleryManager.buildThumbs(forAlbum: albumName)
        }
        
        editButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.editingRx.accept(true)

        }).disposed(by: disposeBag)

        doneButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.editingRx.accept(false)
        }).disposed(by: disposeBag)
        
        addImageButton.rx.tap.subscribe(onNext: { [weak self] in
            let alert = UIAlertController(title: "Select source", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("SELECTFROMFILES", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showDocumentPicker()
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Select from Gallery", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showImagePicker()
            })

            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self?.addImageButton
                presenter.sourceRect = self?.addImageButton.bounds ?? CGRect(origin: .zero, size: .zero)
                presenter.delegate = self
            }

            self?.present(alert, animated: true, completion: nil)
        }).disposed(by: disposeBag)

        self.navigationItem.title = albumName ?? "All Photos"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addImageButton)

        screenView.collectionView.delegate = self
        screenView.collectionView.dataSource = self

        editingRx.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let doneButton = self?.doneButton, let editButton = self?.editButton {
                if value {
                    self?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: doneButton)
                } else {
                    self?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: editButton)
                }
            }
        }).disposed(by: disposeBag)

        let gestureRecongizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
            screenView.collectionView.addGestureRecognizer(gestureRecongizer)
            screenView.collectionView.register(AlbumImageCell.self, forCellWithReuseIdentifier: self.cellName)
        self.refreshData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    func importPhoto(filename: AlbumImage, to album: String) {
        self.listedImages.append(filename)
        if let albumName = albumName {
            galleryManager.rebuildAlbumIndex(folder: galleryManager.selectedGalleryPath.appendingPathComponent(albumName))
        }
        self.refreshData()
    }
    
    func setupViews() {
        self.view = screenView
    }
    
    public func refreshData() {
//        self.listedImages = galleryManager.listImages(album: albumName ?? nil)
        if let albumName = albumName {
            self.listedImages = try! galleryManager.loadAlbumIndex(folder: galleryManager.selectedGalleryPath.appendingPathComponent(albumName))!.images
        } else {
            self.listedImages = galleryManager.listAllImages()
        }
        screenView.collectionView.reloadData()
    }
    
    @objc func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let targetIndexPath = collectionView?.indexPathForItem(at: gesture.location(in: collectionView)) else {
            return
        }

        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1, animations: {
                (self.collectionView!.cellForItem(at: targetIndexPath) as! AlbumImageCell).transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            })
            collectionView?.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView?.endInteractiveMovement()
        case .cancelled:
            collectionView?.cancelInteractiveMovement()
        default:
            print("Default")
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.collectionView?.allowsMultipleSelection = editing
        self.collectionView?.indexPathsForVisibleItems.forEach { (indexPath) in
            let cell = collectionView?.cellForItem(at: indexPath) as! AlbumImageCell
            cell.isEditing = editing
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var temp = listedImages.remove(at: sourceIndexPath.item)
        listedImages.insert(temp, at: destinationIndexPath.item)

        let newGalleryIndex = AlbumIndex(name: galleryManager.selectedGalleryPath.lastPathComponent, images: listedImages ?? [AlbumImage](), thumbnail: listedImages.first?.fileName ?? "")
        galleryManager.updateAlbumIndex(folder: galleryManager.selectedGalleryPath, index: newGalleryIndex)
        collectionView.reloadData()
        return
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                     image: UIImage(systemName: "arrow.up.square")) { action in
//                self.performInspect(indexPath)
            }
            let moveToAlbum = UIAction(title: NSLocalizedString("MoveToAlbum", comment: ""),
                                       image: UIImage(systemName: "square.and.arrow.down")) { [weak self] action in
                let container = ContainerBuilder.build()
                let albumsVC = container.resolve(AlbumsViewController.self)!
                let newController = UINavigationController(rootViewController: albumsVC)
                newController.view.backgroundColor = .systemBackground
                self?.present(newController, animated: true, completion: nil)
                              }
            let duplicateAction =
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
//                self.performDuplicate(indexPath)
            }
            let deleteAction =
            UIAction(title: NSLocalizedString("DeleteImage", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
//                self.performDelete(indexPath)
            }
            return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, deleteAction])
        })
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listedImages.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellName, for: indexPath) as! AlbumImageCell
        if let albumName = albumName {
            let fullImageURL = galleryManager.selectedGalleryPath.appendingPathComponent(self.albumName ?? "").appendingPathComponent(listedImages[indexPath.row].fileName)
            let path = fullImageURL.path
            cell.albumImage.image = UIImage(contentsOfFile: path)
            print("")
        } else {
            let fullImageURL = galleryManager.selectedGalleryPath.appendingPathComponent(listedImages[indexPath.row].fileName)
            let path = fullImageURL.path
            cell.albumImage.image = UIImage(contentsOfFile: path)
        }
        cell.index = indexPath.row
        cell.delegate = self
        editingRx.subscribe(onNext: { value in
            cell.isEditingRX.accept(value)
        }).dispose()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

}

extension AlbumScreenViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let d = galleryManager.selectedGalleryPath
                
        for url in urls {
            do {
                try FileManager.default.moveItem(at: url, to: d.appendingPathComponent(albumName ?? "").appendingPathComponent(url.lastPathComponent))
                self.importPhoto(filename: AlbumImage(fileName: url.lastPathComponent, date: Date()), to: albumName ?? "")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension AlbumScreenViewController: UIPopoverPresentationControllerDelegate {
    
}

extension AlbumScreenViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageURL = info[.imageURL] as? URL {
            print(imageURL)
            do {
                try FileManager().moveItem(at: imageURL, to: galleryManager.selectedGalleryPath.appendingPathComponent(albumName ?? "").appendingPathComponent(imageURL.lastPathComponent))
                self.importPhoto(filename: AlbumImage(fileName: imageURL.lastPathComponent, date: Date()), to: albumName ?? "")
            } catch {
                print(error.localizedDescription)
            }
            self.imagePicker.dismiss(animated: true)
        }
    }
}
