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
import ImageViewer

class AlbumScreenViewController: UIViewController {
    
    // -- MARK: Views
    lazy var screenView = AlbumScreenView()
    
    // -- MARK: Properties
    var viewModel: AlbumScreenViewModel
    let router: AlbumScreenRouter
    
//    var imagesToBeAdded = [AlbumImage]()
    
    let disposeBag = DisposeBag()
    
    // MARK: - Progress
    var importProgress = MutableProgress()
    
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
        
        self.viewModel.isEditing.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let editButton = self?.screenView.editButton {
                if value {
                    editButton.setTitle(NSLocalizedString("kDONE", comment: ""), for: .normal)
                    self?.setEditing(true, animated: true)
                } else {
                    editButton.setTitle(NSLocalizedString("kEDIT", comment: ""), for: .normal)
                    self?.setEditing(false, animated: true)
                    self?.screenView.collectionView.indexPathsForVisibleItems.forEach { index in
                        let cell = self?.screenView.collectionView.cellForItem(at: index) as! AlbumImageCell
//                        cell.isEditing = false
                        cell.checkBox.checker = false
                        cell.checkBox.isEnabled = false
                    }
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
        
        self.screenView.progressView.observedProgress = self.viewModel.importProgress
        
        self.viewModel.showingLoading.map { value in
            !value
        }.bind(to: self.screenView.loadingView.rx.isHidden).disposed(by: disposeBag)
        
        self.viewModel.showImportError.subscribe(onNext: { filesThatCouldntBeImported in
            if !filesThatCouldntBeImported.isEmpty {
                let alert = UIAlertController(title: "Alert", message: "Could not import files \(filesThatCouldntBeImported)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    switch action.style{
                    case .default:
                        print("default")
                        
                    case .cancel:
                        print("cancel")
                        
                    case .destructive:
                        print("destructive")
                        
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
        
        self.viewModel.showingTitles.subscribe(onNext: { value in
            self.screenView.checkBoxTitles.checker = value
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Interactions Binding
    func bindInteractions() {
        self.screenView.editButton.rx.tap.subscribe(onNext: { [weak self] in
            if self?.viewModel.isEditing.value == false {
                self?.viewModel.isEditing.accept(true)
            } else {
                self?.viewModel.isEditing.accept(false)
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
        
        self.screenView.checkBoxTitles.rx.tap.subscribe(onNext: { [weak self] in
            if self?.viewModel.showingTitles.value != false {
                self?.viewModel.showingTitles.accept(false)
            } else {
                self?.viewModel.showingTitles.accept(true)
            }
        }).disposed(by: disposeBag)
        
        // MARK: - Slider binding
        self.screenView.slider.rx.value.changed.subscribe(onNext: { value in
            let newValue = CGFloat(value)
            
            self.screenView.collectionLayout.itemSize = CGSize(width: newValue, height: newValue)

            DispatchQueue.global(qos: .userInteractive).async {
                self.viewModel.newThumbnailSize(size: value)
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
//            cell.isEditing = editing
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
        let thumbnailURL = self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(kThumbs).appendingPathComponent(self.viewModel.images[indexPath.row].fileName).deletingPathExtension().appendingPathExtension("jpg").relativePath
        let fullImageURL = self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(self.viewModel.images[indexPath.row].fileName)
        self.viewModel.galleryManager.buildThumb(forImage: self.viewModel.images[indexPath.row])

        cell.imageView.image = UIImage(contentsOfFile: thumbnailURL)
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

// TODO: Refactor - move this fction to viewModel
extension AlbumScreenViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        self.viewModel.importPHResults(results: results)
    }
}
