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

enum GallerySection: String {
    case main
}

struct GalleryItem: Hashable {
    let title: String?
    let image: UIImage
    private let identifier = UUID()
}

class AlbumScreenViewController: UIViewController {
    
    // -- MARK: Views
    lazy var screenView = AlbumScreenView()
    
    // -- MARK: Properties
    var viewModel: AlbumScreenViewModel
    let router: AlbumScreenRouter
    let disposeBag = DisposeBag()
    var editingRx = BehaviorRelay<Bool>(value: false)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.bindInteractions()
                
        self.editingRx.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let editButton = self?.screenView.editButton {
                if value {
                    self?.screenView.editButton.setTitle(NSLocalizedString("kDONE", comment: ""), for: .normal)
                } else {
                    self?.screenView.editButton.setTitle(NSLocalizedString("kEDIT", comment: ""), for: .normal)
                }
            }
        }).disposed(by: disposeBag)
        
        self.screenView.slider.rx.value.changed.subscribe(onNext: { value in
            let newValue = CGFloat(value)
            self.screenView.collectionLayout.itemSize = CGSize(width: newValue, height: newValue)
//            print(value) // Prints current slider value to console
        }).disposed(by: disposeBag)
        
        self.refreshData()
    }
    
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
    
    init(router: AlbumScreenRouter, viewModel: AlbumScreenViewModel) {
        self.router = router
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        screenView.collectionViewLayout2.itemSize = CGSize(width: self.screenView.frame.width / 3.3, height: self.screenView.frame.height / 3.3)
        screenView.collectionViewLayout2.invalidateLayout()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        screenView.collectionViewLayout2.itemSize = CGSize(width: self.screenView.frame.width / 3.3, height: self.screenView.frame.height / 3.3)
        screenView.collectionViewLayout2.invalidateLayout()
    }
    
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    func addPhoto(filename: AlbumImage, to album: UUID? = nil) {
        self.viewModel.galleryManager.addImage(photoID: filename.fileName)
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
        let temp = self.viewModel.listedImages.remove(at: sourceIndexPath.item)
        self.viewModel.listedImages.insert(temp, at: destinationIndexPath.item)

        let newGalleryIndex = AlbumIndex(name: self.viewModel.galleryManager.selectedGalleryPath.lastPathComponent, images: self.viewModel.listedImages, thumbnail: self.viewModel.listedImages.first?.fileName ?? "")
        self.viewModel.galleryManager.updateAlbumIndex(folder: self.viewModel.galleryManager.selectedGalleryPath, index: newGalleryIndex)
        collectionView.reloadData()
        return
    }

    // Long Press Menu on Image cell
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("kDETAILS", comment: ""),
                     image: UIImage(systemName: "info.circle")) { action in
                let newView = UIView()
                newView.backgroundColor = .green
                self.router.showDetails(images: [UUID()])
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
            UIAction(title: NSLocalizedString("kDELETEIMAGE", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                let imageName = self.viewModel.listedImages[indexPath.row].fileName
                self.viewModel.deleteImage(imageName: imageName)
            }
            return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, deleteAction])
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = screenView.collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenFooter.identifier, for: indexPath) as! AlbumScreenFooter
        return footer
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumImageCell.identifier, for: indexPath) as! AlbumImageCell
        let fullImageURL = self.viewModel.galleryManager.selectedGalleryPath.appendingPathComponent(self.viewModel.listedImages[indexPath.row].fileName)
        let path = fullImageURL.path
        cell.imageView.image = UIImage(contentsOfFile: path)
        cell.router = self.router
        cell.index = indexPath.row
        cell.delegate = self
        cell.configure(imageData: self.viewModel.listedImages[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        CGSize(width: view.frame.width, height: 200)
    }
}

extension AlbumScreenViewController: UICollectionViewDelegateFlowLayout {
    
}

extension AlbumScreenViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.listedImages.count
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
