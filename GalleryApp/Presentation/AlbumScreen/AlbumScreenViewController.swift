//
//  EmptyViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import UniformTypeIdentifiers
import SnapKit
import LocalAuthentication
import Swinject
import Photos
import PhotosUI

class AlbumScreenViewController: UIViewController {
    
    // -- MARK: Views
    lazy var screenView = AlbumScreenView()
    
    // -- MARK: Properties
    var viewModel: AlbumScreenViewModel
    let router: AlbumScreenRouter
    let disposeBag = DisposeBag()
    var editingRx = BehaviorRelay<Bool>(value: false)
    var showingTitles = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(router: AlbumScreenRouter, viewModel: AlbumScreenViewModel) {
        self.router = router
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.router.start(navigationController: self.navigationController)
        
        self.setupViews()
        self.bindData()
        self.bindInteractions()
        
        self.editingRx.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let editButton = self?.screenView.editButton {
                if value {
                    editButton.setTitle(NSLocalizedString("kDONE", comment: ""), for: .normal)
                    self?.setEditing(true, animated: true)
                } else {
                    editButton.setTitle(NSLocalizedString("kEDIT", comment: ""), for: .normal)
                    self?.setEditing(false, animated: false)
                }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        screenView.collectionLayout.invalidateLayout()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        screenView.collectionLayout.invalidateLayout()
    }

    // MARK: - Layout
    func setupViews() {
        self.view = screenView
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.screenView.rightStackView)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPressRecognizer.numberOfTapsRequired = 1
        
        self.screenView.collectionView.delegate = self
        self.screenView.collectionView.dataSource = self
        
        self.screenView.collectionView.addGestureRecognizer(longPressRecognizer)
        self.screenView.collectionView.register(AlbumImageCell.self, forCellWithReuseIdentifier: AlbumImageCell.identifier)
        self.screenView.collectionView.register(AlbumScreenFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenFooter.identifier)
        
        if let thumbnailSize = self.viewModel.albumIndex?.thumbnailsSize {
            self.screenView.collectionLayout.itemSize = CGSize(width: CGFloat(thumbnailSize), height: CGFloat(thumbnailSize))
            self.screenView.slider.value = thumbnailSize
        } else {
            self.viewModel.galleryManager.galleryObservable().subscribe(onNext: { index in
                if let thumbnailSize = index.thumbnailSize {
                    self.screenView.collectionLayout.itemSize = CGSize(width: CGFloat(thumbnailSize), height: CGFloat(thumbnailSize))
                    self.screenView.slider.value = thumbnailSize
                }
            }).disposed(by: disposeBag)
        }
    }

    func showDocumentPicker() {
        self.screenView.documentPicker.delegate = self
        self.screenView.documentPicker.allowsMultipleSelection = true
        self.present(self.screenView.documentPicker, animated: true)
    }

    func showImagePicker() {
        self.screenView.imagePicker.delegate = self
        self.present(self.screenView.imagePicker, animated: true)
    }
    
    // MARK: - Data Binding
    func bindData() {
        self.viewModel.loadGalleryIndex().subscribe(onNext: { galleryIndex in
            self.refreshData()
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Interactions Binding
    func bindInteractions() {
        self.screenView.editButton.rx.tap.subscribe(onNext: { [weak self] in
            if self?.editingRx.value == false {
                self?.editingRx.accept(true)
            } else {
                self?.editingRx.accept(false)
            }
        }).disposed(by: disposeBag)
        
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
        
        self.screenView.checkBoxTitles.rx.tap.subscribe(onNext: {
            self.showingTitles.accept(true)
        }).disposed(by: disposeBag)
        
        // MARK: - Slider binding
        self.screenView.slider.rx.value.changed.subscribe(onNext: { value in
            let newValue = CGFloat(value)
            
            self.screenView.collectionLayout.itemSize = CGSize(width: newValue, height: newValue)

            /*
             This compares curren slider value with value -0.5 second, if equal, it will update thumbnail on index in json
             */
            let seconds = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                let currentValue = self.screenView.slider.value
                let oldValue = value
                
                if oldValue == currentValue {
                    self.viewModel.newThumbnailSize(size: value)
                }
            }
        }).disposed(by: disposeBag)
    }

    func addPhoto(filename: AlbumImage, to album: UUID? = nil) {
        self.viewModel.addPhoto(image: filename)
    }

    public func refreshData() {
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
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = self.viewModel.images.remove(at: sourceIndexPath.item)
        self.viewModel.images.insert(temp, at: destinationIndexPath.item)

        let newGalleryIndex = AlbumIndex(name: self.viewModel.galleryManager.selectedGalleryPath.lastPathComponent, images: self.viewModel.images, thumbnail: self.viewModel.images.first?.fileName ?? "")
        self.viewModel.galleryManager.updateAlbumIndex(index: newGalleryIndex)
        collectionView.reloadData()
        return
    }

    // Long Press Menu on Image cell
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: { [self] suggestedActions in
            let inspectAction = UIAction(title: NSLocalizedString("kDETAILS", comment: ""),
                     image: UIImage(systemName: "info.circle")) { action in
                let newView = UIView()
                newView.backgroundColor = .green

                let photoID = self.viewModel.images[indexPath.row]
                                
                self.router.showDetails(images: [photoID])
            }
            
            let selectedImage = self.viewModel.images[indexPath.row]
            
            
            let moveToAlbum = UIAction(title: NSLocalizedString("MoveToAlbum", comment: ""),
                                       image: UIImage(systemName: "square.and.arrow.down")) { [weak self] action in
                let container = ContainerBuilder.build()
                let albumsVC = container.resolve(AlbumsListViewController.self, argument: [selectedImage.fileName])! // TODO: Send actual picture names
                let newController = UINavigationController(rootViewController: albumsVC)
                newController.view.backgroundColor = .systemBackground
                self?.present(newController, animated: true, completion: nil)
            }
            let duplicateAction =
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                //                self.performDuplicate(indexPath)
            }
            let setThumbnailAction =
            UIAction(title: NSLocalizedString("SetThumbnail", comment: ""),
                     image: UIImage(systemName: "rectangle.portrait.inset.filled")) { action in
                let selectedThumbnailFileName = self.viewModel.images[indexPath.row].fileName
                self.viewModel.setAlbumThumbnail(imageName: selectedThumbnailFileName)
            }
            let deleteAction =
            UIAction(title: NSLocalizedString("kDELETEIMAGE", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                let imageName = self.viewModel.images[indexPath.row].fileName
                self.viewModel.deleteImage(imageName: imageName)
            }
            if viewModel.albumID != nil {
                return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, setThumbnailAction, deleteAction])
            } else {
                return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, deleteAction])
            }
        })
    }
}

extension AlbumScreenViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - Dequeing footer cell
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = screenView.collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenFooter.identifier, for: indexPath) as! AlbumScreenFooter
        return footer
    }
    
    // MARK: - Dequeing main cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumImageCell.identifier, for: indexPath) as! AlbumImageCell
        let fullImageURL = self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(self.viewModel.images[indexPath.row].fileName)
        let path = fullImageURL.relativePath
        cell.imageView.image = UIImage(contentsOfFile: path)
        cell.router = self.router
        cell.index = indexPath.row
        cell.viewModel = self.viewModel
        cell.configure(imageData: self.viewModel.images[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        CGSize(width: view.frame.width, height: 200)
    }
}

extension AlbumScreenViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.images.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
}

extension AlbumScreenViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            do {
                try FileManager.default.moveItem(at: url, to: self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(url.lastPathComponent))
                self.addPhoto(filename: AlbumImage(fileName: url.lastPathComponent, date: Date()), to: viewModel.albumIndex?.id as UUID?)
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
                try FileManager().moveItem(at: imageURL, to: self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(self.viewModel.albumIndex?.name ?? "").appendingPathComponent(imageURL.lastPathComponent))
                self.addPhoto(filename: AlbumImage(fileName: imageURL.lastPathComponent, date: Date()), to: self.viewModel.albumID)
            } catch {
                print(error.localizedDescription)
            }
            self.screenView.imagePicker.dismiss(animated: true)
        }
    }
}

extension AlbumScreenViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProviders = results.map { $0.itemProvider }
        
        for itemProvider in itemProviders {
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                guard let filename = itemProvider.suggestedName else { return }

                print("\(results.first?.assetIdentifier)")
                
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    guard let identifier = itemProvider.registeredTypeIdentifiers.first else { return }
                    guard let filenameExtension = URL(string: identifier)?.pathExtension else { return }
                    
                    let resultPath = self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(UUID().uuidString).appendingPathExtension(filenameExtension)
                    
                    guard let image = image as? UIImage else { return }
                    
                    if filenameExtension == "jpeg" || filenameExtension == "jpg" {
                        if let data = image.jpegData(compressionQuality: 1.0) {
                            do {
                                try data.write(to: resultPath)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    } else if filenameExtension == "png" {
                        if let data = image.pngData() {
                            do {
                                try data.write(to: resultPath)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }
                    
                    self.addPhoto(filename: AlbumImage(fileName: resultPath.lastPathComponent, date: Date()), to: self.viewModel.albumID)
                }
            }
        }
    }
}
