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
    
    // MARK: Views
    private var screenView = AlbumScreenView()
	private let searchController = UISearchController(searchResultsController: nil)
	
    // MARK: Properties
    private var viewModel: AlbumScreenViewModel
    private let router: AlbumScreenRouter
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AlbumScreenSectionModel>!
	private let pathResolver: PathResolver
    private let disposeBag = DisposeBag()
    
    // MARK: - Progress
    var importProgress = MutableProgress()
	    
    // MARK: - INIT
	init(router: AlbumScreenRouter, viewModel: AlbumScreenViewModel, pathResolver: PathResolver) {
        self.router = router
        self.viewModel = viewModel
		self.pathResolver = pathResolver
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
        self.router.setup(navigationController: self.navigationController)
		self.setupDataSource()
        self.setupViews()
		self.setupViewOptionsMenu()
        self.bindData()
		self.bindUIState()
        self.bindInteractions()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
	// MARK: - Data Source
    func setupDataSource() {
        dataSource = RxCollectionViewSectionedAnimatedDataSource<AlbumScreenSectionModel>(
            configureCell: { [unowned self] (dataSource, collectionView, indexPath, sectionModelItem) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumScreenCell.identifier, for: indexPath) as! AlbumScreenCell
				cell.setup(with: sectionModelItem, viewModel: self.viewModel, pathResolver: self.pathResolver)
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
		
		self.navigationItem.searchController = self.searchController
		
		self.screenView.collectionView.allowsSelectionDuringEditing = true
        self.screenView.collectionView.delegate = self
        self.screenView.collectionView.register(AlbumScreenCell.self, forCellWithReuseIdentifier: AlbumScreenCell.identifier)
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
        
        self.viewModel.showingLoading
            .map { value in
                !value
            }
            .bind(to: self.screenView.loadingView.rx.isHidden)
            .disposed(by: disposeBag)
        
        self.viewModel.errorMessage.subscribe(onNext: { [weak self] errorMessage in
            if !errorMessage.isEmpty {
                let alert = UIAlertController(title: "Alert", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "kOK", style: .cancel))
                self?.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
        
        // MARK: - Loading Images to Collection View
		Observable.combineLatest(viewModel.imagesAsObservable(), searchController.searchBar.rx.text)
			.map { (images, searchTerm) in
				return images.filter { image in
					guard let searchTerm = searchTerm, !searchTerm.isEmpty else { return true }
					return image.title?.lowercased().contains(searchTerm.lowercased()) ?? false
				}
			}
			.compactMap { images in
				[AlbumScreenSectionModel(items: images)]
			}
			.bind(to: self.screenView.collectionView.rx.items(dataSource: self.dataSource))
			.disposed(by: disposeBag)
    }
	
	func bindUIState() {
		self.viewModel.showingAnnotationsAsObservable().subscribe(onNext: { [weak self] showing in
			self?.screenView.viewButton.menu?.children.forEach { action in
				if action.title == NSLocalizedString("kSHOWINGTITLESON", comment: "Showing titles on") {
					print("Selected")
					guard let action = action as? UIAction else {return}
					if showing {
						action.state = .on
					}
				}
				
				if action.title == NSLocalizedString("kSHOWINGTITLESOFF", comment: "Showing titles off") {
					print("Unselected")
					guard let action = action as? UIAction else {return}
					if !showing {
						action.state = .off
					}
				}
			}
		}).disposed(by: disposeBag)
		
		self.viewModel.sliderValueAsObservable()
			.do(onNext: { [weak self] value in
				self?.screenView.collectionLayout.itemSize = CGSize(width: CGFloat(value), height: CGFloat(value))
			})
			.asDriver(onErrorJustReturn: 0.0)
			.drive(screenView.slider.rx.value)
			.disposed(by: disposeBag)
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
        
		// MARK: - Editing Button binding
        self.viewModel.isEditing.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let editButton = self?.screenView.editButton {
                if value {
                    editButton.setTitle(NSLocalizedString("kDONE", comment: ""), for: .normal)
                    editButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
					self?.screenView.deleteImageButton.isHidden = false
					self?.screenView.addImageButton.isHidden = true
                } else {
                    editButton.setTitle(NSLocalizedString("kEDIT", comment: ""), for: .normal)
                    editButton.titleLabel?.font = .systemFont(ofSize: 18)
					self?.screenView.deleteImageButton.isHidden = true
					self?.screenView.addImageButton.isHidden = false

					
                    self?.screenView.collectionView.indexPathsForVisibleItems.forEach { index in
                        let cell = self?.screenView.collectionView.cellForItem(at: index) as! AlbumScreenCell
                        cell.hideSelectedView()
                    }
                }
            }
        }).disposed(by: disposeBag)
        
        self.viewModel.isEditing.subscribe(onNext: { [weak self] value in
            guard let self else { return }
			
			self.screenView.collectionView.allowsMultipleSelection = value
            
            if value {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.screenView.leftStackView)
            } else {
                self.navigationItem.leftBarButtonItem = nil
            }
        }).disposed(by: disposeBag)
        
        self.screenView.addImageButton.rx.tap.subscribe(onNext: { [weak self] in
            let alert = UIAlertController(title: NSLocalizedString("kIMPORTFROM", comment: "Select import location"), message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("kSELECTFROMFILES", comment: "Default action"), style: .default) { [weak self] _ in
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
			if self?.isEditing == true {
				guard let self else { return }
				guard let indexes = self.screenView.collectionView.indexPathsForSelectedItems else { return }
				let selectedImages = indexes.compactMap { self.dataSource.sectionModels.first?.items[$0.item] ?? nil }
				self.viewModel.delete(selectedImages)
				self.viewModel.isEditing.accept(false)
			}
        }).disposed(by: disposeBag)
        
        // MARK: - Slider binding
		self.screenView.slider.rx.value.changed
            .map { CGFloat($0) }
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] value in
                self?.screenView.collectionLayout.itemSize = CGSize(width: value, height: value)
            })
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] value in
                self?.viewModel.updateThumbnailSize(size: Float(value))
            }).disposed(by: disposeBag)
	}
	
	func setupViewOptionsMenu() {
		let offOption = UIAction(title: NSLocalizedString("kSHOWINGTITLESOFF", comment: "Showing titles off")) { [weak self] (action: UIAction) in
			self?.viewModel.updateShowingAnnotations(value: false)
		}
		let showTitlesOption = UIAction(title: NSLocalizedString("kSHOWINGTITLESON", comment: "Showing titles on")) { [weak self] (action: UIAction) in
			self?.viewModel.updateShowingAnnotations(value: true)
		}
		self.screenView.viewButton.menu = UIMenu(options: .singleSelection, children: [offOption, showTitlesOption])
	}
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return
    }
    
	func getSelectedImages(for indexPath: IndexPath) -> [GalleryImage] {
		guard let selectedIndexes = screenView.collectionView.indexPathsForSelectedItems, !selectedIndexes.isEmpty else {
			return [dataSource[indexPath]]
		}		
		return selectedIndexes.compactMap { dataSource.sectionModels.first?.items[$0.row] }
	}
}

// MARK: - Collection View Delegate
extension AlbumScreenViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { [weak self] suggestedActions in
            
            guard let selectedImages = self?.getSelectedImages(for: indexPath) else { return UIMenu() }
            
            let inspectAction = UIAction(title: NSLocalizedString("kDETAILS", comment: ""),
                                         image: UIImage(systemName: "info.circle")) { action in
                self?.router.showPropertiesScreen(of: selectedImages)
            }
            
            let moveToAlbum = UIAction(title: NSLocalizedString("MoveToAlbum", comment: ""),
                                       image: UIImage(systemName: "square.and.arrow.down")) { [weak self] action in
                
                self?.router.showMoveToAlbumScreen(with: selectedImages)
            }
            let duplicateAction =
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                if let item = self?.dataSource.sectionModels[indexPath.section].items[indexPath.row] {
					self?.viewModel.duplicateItem(images: [item])
                }
            }
            let setThumbnailAction =
            UIAction(title: NSLocalizedString("SetThumbnail", comment: ""),
                     image: UIImage(systemName: "rectangle.portrait.inset.filled")) { action in
                if let selectedThumbnailFileName = self?.dataSource.sectionModels[indexPath.section].items[indexPath.row] {
                    self?.viewModel.setAlbumThumbnailImage(image: selectedThumbnailFileName)
                }
            }
            let removeFromAlbum =
            UIAction(title: NSLocalizedString("kREMOVEFROMALBUM", comment: ""),
                     image: UIImage(systemName: "rectangle.stack.badge.minus"),
                     attributes: .destructive) { action in
                self?.viewModel.removeFromAlbum(images: selectedImages)
            }
            let deleteAction =
            UIAction(title: NSLocalizedString("kDELETEIMAGE", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
				if collectionView.isEditing == true {
					self?.viewModel.delete(selectedImages.map { $0 })
					self?.viewModel.isEditing.accept(false)
				}
            }
            if self?.viewModel.albumID != nil {
                return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, setThumbnailAction, removeFromAlbum, deleteAction])
            } else {
                return UIMenu(title: "", children: [inspectAction, moveToAlbum, duplicateAction, deleteAction])
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? AlbumScreenCell {
            if isEditing {
				cell.showSelectedView()
            } else {
				if let images = self.dataSource.sectionModels.first?.items.map({ $0 }) {
                    self.router.showPhotoDetail(images: images, index: indexPath)
                }
            }
        }
    }
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		if isEditing, let cell = collectionView.cellForItem(at: indexPath) as? AlbumScreenCell {
			cell.hideSelectedView()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? AlbumScreenCell {
			cell.hideSelectedView()
		}
	}
}

extension AlbumScreenViewController: UIPopoverPresentationControllerDelegate {}

extension AlbumScreenViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.viewModel.handleImportFromFilesApp(urls: urls)
    }
}

extension AlbumScreenViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        self.viewModel.handleImportFromPhotosApp(results: results)
    }
}


extension AlbumScreenViewController: AlbumListViewControllerDelegate {
    func didFinishMovingImages() {
        self.isEditing = false
        self.viewModel.isEditing.accept(false)
    }
}
