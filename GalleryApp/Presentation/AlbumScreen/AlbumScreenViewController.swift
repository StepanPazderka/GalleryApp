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
import Swinject
import PhotosUI

class AlbumScreenViewController: UIViewController {
    
    // -- MARK: Views
    lazy var screenView = AlbumScreenView()
    
    // -- MARK: Properties
    var viewModel: AlbumScreenViewModel
    let router: AlbumScreenRouter
    let disposeBag = DisposeBag()
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, AlbumImage>>!
    var transitionImageView: UIImageView?
    
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
        self.configureDataSource()
        
        self.router.start(navigationController: self.navigationController)
        
        self.setupViews()
        self.bindData()
        self.bindInteractions()
        
        self.viewModel.isEditing.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let editButton = self?.screenView.editButton {
                if value {
                    editButton.setTitle(NSLocalizedString("kDONE", comment: ""), for: .normal)
                    editButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
                    self?.setEditing(true, animated: true)
                    self?.screenView.collectionView.indexPathsForVisibleItems.forEach { index in
                        let cell = self?.screenView.collectionView.cellForItem(at: index) as! AlbumImageCell
                        cell.isEditing = true
                    }
                } else {
                    editButton.setTitle(NSLocalizedString("kEDIT", comment: ""), for: .normal)
                    editButton.titleLabel?.font = .systemFont(ofSize: 18)
                    self?.setEditing(false, animated: true)
                    self?.screenView.collectionView.indexPathsForVisibleItems.forEach { index in
                        let cell = self?.screenView.collectionView.cellForItem(at: index) as! AlbumImageCell
                        cell.isEditing = false
                        self?.viewModel.filesSelectedInEditMode.removeAll()
                    }
                }
            }
        }).disposed(by: disposeBag)
        
        self.viewModel.loadAlbumImagesObservable().flatMap { albumImages in
            return Observable.just([AnimatableSectionModel(model: "Something", items: albumImages)])
        }.bind(to: self.screenView.collectionView.rx.items(dataSource: self.dataSource)).disposed(by: disposeBag)
    }
    
    func configureDataSource() {
        dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, AlbumImage>>(
            configureCell: { (dataSource, collectionView, indexPath, item) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumImageCell.identifier, for: indexPath) as! AlbumImageCell
                cell.configure(with: item, viewModel: self.viewModel)
                cell.index = indexPath.item
                return cell
            }
        )
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
        self.screenView.collectionView.addGestureRecognizer(longPressRecognizer)
        self.screenView.collectionView.register(AlbumImageCell.self, forCellWithReuseIdentifier: AlbumImageCell.identifier)
        self.screenView.collectionView.register(AlbumScreenCellFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenCellFooter.identifier)
        
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
        let imagePicker = self.screenView.imagePicker()
        
        imagePicker.delegate = self
        self.present(imagePicker, animated: true)
    }
    
    // MARK: - Data Binding
    func bindData() {
        self.screenView.progressView.observedProgress = self.viewModel.importProgress
        
        self.viewModel.showingLoading.map { value in
            !value
        }.bind(to: self.screenView.loadingView.rx.isHidden).disposed(by: disposeBag)
        
        self.viewModel.showImportError.subscribe(onNext: { filesThatCouldntBeImported in
            if !filesThatCouldntBeImported.isEmpty {
                let alert = UIAlertController(title: "Alert", message: "Could not import files \(filesThatCouldntBeImported.joined(separator: ", "))", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
        
        self.viewModel.showingTitles
            .distinctUntilChanged()
            .subscribe(onNext: { value in
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
        
        // MARK: - User Selected Cell
        self.screenView.collectionView.rx.itemSelected.subscribe(onNext: { [unowned self] indexPath in
            let cell = self.screenView.collectionView.cellForItem(at: indexPath) as! AlbumImageCell
            
            if self.isEditing == false {
                self.router.showPhotoDetail(images: self.viewModel.images, index: indexPath.row)
            } else {
                cell.checkBox.checker.toggle()
                if cell.checkBox.checker == true {
                    viewModel.filesSelectedInEditMode.append(viewModel.images[indexPath.row].fileName)
                } else {
                    viewModel.filesSelectedInEditMode.removeAll { $0 == viewModel.images[indexPath.row].fileName }
                }
            }
        }).disposed(by: disposeBag)
        
        self.viewModel.isEditing.subscribe(onNext: { [weak self] value in
            guard let self else { return }
            
            if value {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.screenView.leftStackView)
            } else {
                self.navigationItem.leftBarButtonItem = nil
            }
        }).disposed(by: disposeBag)
        
        self.screenView.addImageButton.rx.tap.subscribe(onNext: { [weak self] in
            let alert = UIAlertController(title: NSLocalizedString("IMPORTFROM", comment: "Select import location"), message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("SELECTFROMFILES", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showDocumentPicker()
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("kSELECTFROMPHOTOLIBRARY", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showImagePicker()
            })

            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self?.screenView.addImageButton
                presenter.sourceRect = self?.screenView.addImageButton.bounds ?? CGRect(origin: .zero, size: .zero)
                presenter.delegate = self
            }

            self?.present(alert, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        self.screenView.deleteImageButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.viewModel.delete(self.viewModel.filesSelectedInEditMode)
            self.viewModel.isEditing.accept(false)
        }).disposed(by: disposeBag)
        
        self.screenView.checkBoxTitles.rx.tap.subscribe(onNext: { [weak self] in
            if self?.viewModel.showingTitles.value != false {
                self?.viewModel.showingTitles.accept(false)
            } else {
                self?.viewModel.showingTitles.accept(true)
            }
        }).disposed(by: disposeBag)
        
        // MARK: - Slider binding
        self.screenView.slider.rx.value.changed
            .map { CGFloat($0) }
            .observe(on: MainScheduler.instance)
            .do(onNext: { value in
                self.screenView.collectionLayout.itemSize = CGSize(width: value, height: value)
            })
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { value in
            DispatchQueue.global(qos: .userInteractive).async {
                self.viewModel.newThumbnailSize(size: Float(value))
            }
        }).disposed(by: disposeBag)
    }

    func addPhoto(filename: AlbumImage, to album: UUID? = nil) {
        self.viewModel.addPhoto(image: filename)
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
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = self.viewModel.images.remove(at: sourceIndexPath.item)
        self.viewModel.images.insert(temp, at: destinationIndexPath.item)

        let newGalleryIndex = AlbumIndex(name: self.viewModel.galleryManager.selectedGalleryPath.lastPathComponent, images: self.viewModel.images, thumbnail: self.viewModel.images.first?.fileName ?? "")
        self.viewModel.galleryManager.updateAlbumIndex(index: newGalleryIndex)
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
                self.viewModel.setAlbumThumbnailImage(imageName: selectedThumbnailFileName)
            }
            let removeFromAlbum =
            UIAction(title: NSLocalizedString("kREMOVEFROMALBUM", comment: ""),
                     image: UIImage(systemName: "rectangle.stack.badge.minus"),
                     attributes: .destructive) { action in
                let imageName = self.viewModel.images[indexPath.row].fileName
                self.viewModel.removeFromAlbum(imageName: imageName)
            }
            let deleteAction =
            UIAction(title: NSLocalizedString("kDELETEIMAGE", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                let imageName = self.viewModel.images[indexPath.row].fileName
                self.viewModel.delete([imageName])
            }
            if viewModel.albumID != nil {
                return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, setThumbnailAction, removeFromAlbum, deleteAction])
            } else {
                return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, deleteAction])
            }
        })
    }
}

extension AlbumScreenViewController: UIPopoverPresentationControllerDelegate {}

extension AlbumScreenViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - Dequeing footer cell
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = screenView.collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AlbumScreenCellFooter.identifier, for: indexPath) as! AlbumScreenCellFooter
        return footer
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        CGSize(width: view.frame.width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle the tap on the selected item here
        
        // You can access the selected item using the index path
        //            let selectedItem = myData[indexPath.item]
        print("User tapped")
        
        // Do something with the selected item
        //            print("Selected item: \(selectedItem)")
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        // Return true for cells that can be moved
        return true
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

// TODO: Refactor - move this fction to viewModel
extension AlbumScreenViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let photos = results
        self.viewModel.importPhotos(results: photos)
    }
}
