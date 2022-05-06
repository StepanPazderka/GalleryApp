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
import SnapKit
import CoreAudio

enum GallerySection: String {
    case main
}

struct GalleryItem: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()
}

class AlbumScreenViewController: UIViewController, ListsImages {
    var galleryManager: GalleryManager
    
    var screenView = AlbumScreenView()
    
    var albumName: String?
    
    var viewModel = AlbumScreenViewModel(albumName: "Test")
        
    let cellName = "AlbumImageCell"
    
    let disposeBag = DisposeBag()
    
    let router: AlbumScreenRouter
    
    public var listedImages: [AlbumImage] = []
        
    var editingRx = BehaviorRelay<Bool>(value: false)

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
    
    init(router: AlbumScreenRouter, galleryInteractor: GalleryManager, albumName: String? = nil) {
        if let albumName = albumName {
            self.albumName = albumName
        }
        self.router = router
        self.galleryManager = galleryInteractor
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        
        if let albumName = albumName {
            galleryManager.buildThumbs(forAlbum: albumName)
        }
        
        self.screenView.editButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.editingRx.accept(true)
        }).disposed(by: disposeBag)

        self.screenView.doneButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.editingRx.accept(false)
            
        }).disposed(by: disposeBag)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.screenView.rightStackView)
        
        self.screenView.addImageButton.rx.tap.subscribe(onNext: { [weak self] in
            let alert = UIAlertController(title: NSLocalizedString("IMPORTFROM", comment: "Select import location"), message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("SELECTFROMFILES", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showDocumentPicker()
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Select from Gallery", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showImagePicker()
            })

            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self?.screenView.addImageButton
                presenter.sourceRect = self?.screenView.addImageButton.bounds ?? CGRect(origin: .zero, size: .zero)
                presenter.delegate = self
            }

            self?.present(alert, animated: true, completion: nil)
        }).disposed(by: disposeBag)

        self.navigationItem.title = albumName ?? "All Photos"
        
        self.screenView.collectionView.delegate = self
        self.screenView.collectionView.dataSource = self

        self.editingRx.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let doneButton = self?.screenView.doneButton, let editButton = self?.screenView.editButton {
                if value {
                    self?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: doneButton)
                } else {
                    self?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: editButton)
                }
            }
        }).disposed(by: disposeBag)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPressRecognizer.numberOfTapsRequired = 1

        self.screenView.collectionView.addGestureRecognizer(longPressRecognizer)
        self.screenView.collectionView.register(AlbumImageCell.self, forCellWithReuseIdentifier: self.cellName)
        self.screenView.collectionView.register(AlbumScreenFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenFooter.identifier)
        self.refreshData()
    }
    
    @objc func tappedCell(sender: UITapGestureRecognizer) {
        print("Tapped \(Date())")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    func addPhoto(filename: AlbumImage, to album: String) {
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
        self.screenView.collectionView.reloadData()
    }
    
    @objc func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let targetIndexPath = self.screenView.collectionView.indexPathForItem(at: gesture.location(in: self.screenView.collectionView)) else {
            return
        }

        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1, animations: {
                (self.screenView.collectionView.cellForItem(at: targetIndexPath) as! AlbumImageCell).transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            })
            self.screenView.collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            self.screenView.collectionView.updateInteractiveMovementTargetPosition(gesture.location(in:self.screenView.collectionView))
        case .ended:
            self.screenView.collectionView.endInteractiveMovement()
        case .cancelled:
            self.screenView.collectionView.cancelInteractiveMovement()
        default:
            print("Default")
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.screenView.collectionView.allowsMultipleSelection = editing
        self.screenView.collectionView.indexPathsForVisibleItems.forEach { (indexPath) in
            let cell = screenView.collectionView.cellForItem(at: indexPath) as! AlbumImageCell
            cell.isEditing = editing
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        CGSize(width: view.frame.width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = listedImages.remove(at: sourceIndexPath.item)
        listedImages.insert(temp, at: destinationIndexPath.item)

        let newGalleryIndex = AlbumIndex(name: galleryManager.selectedGalleryPath.lastPathComponent, images: listedImages, thumbnail: listedImages.first?.fileName ?? "")
        galleryManager.updateAlbumIndex(folder: galleryManager.selectedGalleryPath, index: newGalleryIndex)
        collectionView.reloadData()
        return
    }

    // Long Press Menu
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("kDETAILS", comment: ""),
                     image: UIImage(systemName: "info.circle")) { action in
//                self.performInspect(indexPath)
                let newView = UIView(frame: CGRect(x: 400, y: 20, width: 500, height: 500))
                newView.backgroundColor = .blue
                
                self.view.addSubview(newView)
//                newView.snp.makeConstraints { (make) -> Void in
//                    make.rightMargin.equalTo(self.view)
//                }
            }
            let moveToAlbum = UIAction(title: NSLocalizedString("MoveToAlbum", comment: ""),
                                       image: UIImage(systemName: "square.and.arrow.down")) { [weak self] action in
                let container = ContainerBuilder.build()
                let albumsVC = container.resolve(AlbumsListViewController.self, argument: ["Test"])!
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
    
    // Fill Collection View With Data
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellName, for: indexPath) as! AlbumImageCell
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tappedCell))
        tapGesture.numberOfTapsRequired = 1
        let fullImageURL = galleryManager.selectedGalleryPath.appendingPathComponent(listedImages[indexPath.row].fileName)
        let path = fullImageURL.path
        cell.albumImage.image = UIImage(contentsOfFile: path)
        cell.index = indexPath.row
        cell.delegate = self
        editingRx.subscribe(onNext: { value in
            cell.isEditingRX.accept(value)
        }).disposed(by: disposeBag)
        cell.addGestureRecognizer(tapGesture)
        return cell
    }
}

extension AlbumScreenViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = screenView.collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenFooter.identifier, for: indexPath) as! AlbumScreenFooter
        return footer
    }
}

extension AlbumScreenViewController: UICollectionViewDelegateFlowLayout {
    
}

extension AlbumScreenViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listedImages.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
}

extension AlbumScreenViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let d = galleryManager.selectedGalleryPath
                
        for url in urls {
            do {
                try FileManager.default.moveItem(at: url, to: d.appendingPathComponent(albumName ?? "").appendingPathComponent(url.lastPathComponent))
                self.addPhoto(filename: AlbumImage(fileName: url.lastPathComponent, date: Date()), to: albumName ?? "")
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
                self.addPhoto(filename: AlbumImage(fileName: imageURL.lastPathComponent, date: Date()), to: albumName ?? "")
            } catch {
                print(error.localizedDescription)
            }
            self.imagePicker.dismiss(animated: true)
        }
    }
}
