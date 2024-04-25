//
//  SelectLibraryViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.04.2023.
//

import Foundation
import UIKit
import RxDataSources
import RxCocoa
import RxSwift

class SelectLibraryViewController: UIViewController {
    
    // MARK: - Views
    private let screenView = SelectLibraryView()
    private let viewModel: SelectLibraryViewModel
	private let pathResolver: PathResolver
	
	private var showingDeleteAlert = BehaviorRelay(value: false)
	private var showingRenameDialog = BehaviorRelay(value: false)
	private var selectedIndex: IndexPath?
	
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<SelectLibraryAnimatableSectionModel>?
    
	init(viewModel: SelectLibraryViewModel, pathResolver: PathResolver) {
        self.viewModel = viewModel
		self.pathResolver = pathResolver

        super.init(nibName: nil, bundle: nil)

        self.configureDataSource()
        self.screenView.galleriesCollectionView.register(SidebarViewCell.self, forCellWithReuseIdentifier: SidebarViewCell.identifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.setupViews()
        self.bindInteractions()
        self.bindData()
		self.bindUI()
    }
    
    private func bindData() {
		self.viewModel.loadAnimatedSectionsForCollectionView()
			.bind(to: screenView.galleriesCollectionView.rx.items(dataSource: dataSource!))
			.disposed(by: disposeBag)
		
		self.viewModel.loadCurrentGalleryAsObservable().subscribe(onNext: { index in
			if let indexPath = self.dataSource?.sectionModels.first?.items.firstIndex(where: { galleryIndex in
				galleryIndex.id == index.id
			}) {
				self.screenView.galleriesCollectionView.selectItem(at: IndexPath(row: indexPath, section: 0), animated: false, scrollPosition: .bottom)
			}
		}).disposed(by: disposeBag)
    }
    
    private func bindInteractions() {
		// MARK: - Switch to another library
        self.screenView.galleriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] index in
            guard let self else { return }
            if let libraryName = self.dataSource?.sectionModels.first?.items[index.item] {
				self.viewModel.switchTo(library: libraryName.id)
                self.dismiss(animated: true)
            }
        }).disposed(by: disposeBag)
        
        // MARK: - Right NavBar button Tap
        self.screenView.rightBarButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.showCreateLibraryDialog(callback: { name in
                do {
                    try self?.viewModel.createNewLibrary(withName: name) {
                    }
                } catch {
                    
                }
            })
        }).disposed(by: disposeBag)
        
        // MARK: - Close Button tap
        self.screenView.closeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        // MARK: - Swipe to Delete Action Closure
        self.screenView.swipeToDeleteHandler = { [weak self] index in
			self?.selectedIndex = index
			self?.showingDeleteAlert.accept(true)
        }
		
		self.screenView.swipeToRenameHandler = { [weak self] index in
			if let galleryIndex = self?.dataSource?[index] {
				self?.showCreateLibraryDialog(withPrepulatedName: galleryIndex.mainGalleryName, callback: { newName in
					self?.viewModel.rename(gallery: galleryIndex, withName: newName)
				})
			}
		}
    }
    
	private func bindUI() {
		self.showingDeleteAlert.subscribe(onNext: { value in
			
			let alertController = UIAlertController(title: "Are you sure", message: "Are you sure you want to delete this library?", preferredStyle: .alert)
			
			let okButton = UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
				if let indexPath = self?.selectedIndex, let galleryName = self?.dataSource?.sectionModels.first?.items[indexPath.row] {
					self?.viewModel.delete(gallery: galleryName.mainGalleryName)
				}
			}
			let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
			
			alertController.addAction(okButton)
			alertController.addAction(cancelButton)
			
			if value == true {
				self.present(alertController, animated: true, completion: nil)
			}
		}).disposed(by: disposeBag)
	}
	
    private func configureDataSource() {
		self.dataSource = RxCollectionViewSectionedAnimatedDataSource<SelectLibraryAnimatableSectionModel>(configureCell: { [weak self] dataSource, collectionView, indexPath, item in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarViewCell.identifier, for: indexPath) as! SidebarViewCell
			cell.label.text = item.mainGalleryName
			if let lastGalleryImage = item.images.first, let thumbnailImagePath = self?.pathResolver.resolveThumbPathFor(imageName: lastGalleryImage.fileName) {
				cell.imageView.image = UIImage(contentsOfFile: thumbnailImagePath)
			} else {
				cell.imageView.image = UIImage(systemName: "square")
			}
			return cell})
    }
    
    // MARK: - Create Album Popover Dialog Box
    @objc private func showCreateLibraryDialog(withPrepulatedName: String? = nil, callback: ((String) -> Void)? = nil) {
        var returnString: String?
        let createAlbumAlert = UIAlertController(title: NSLocalizedString("kEnterLibraryName", comment: ""), message: nil, preferredStyle: .alert)

        createAlbumAlert.addTextField { textField in
            textField.placeholder = NSLocalizedString("kLibraryName", comment: "Library name")
            
            if let withPrepulatedName {
                textField.text = withPrepulatedName
            }
        }
                
        let confirmAction = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .default) { [weak createAlbumAlert] _ in
            guard let alertController = createAlbumAlert, let textField = alertController.textFields?.first, let text = textField.text else { return }
            
            if text.isEmpty {
                let okAction = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .destructive)
                
                let noAlbumAlert = UIAlertController(title: NSLocalizedString("kNameCantBeEmpty", comment: ""), message: nil, preferredStyle: .alert)
                noAlbumAlert.addAction(okAction)
                self.present(noAlbumAlert, animated: true)
                returnString = nil
                return
            }
            
            if let albumName = textField.text, !text.isEmpty {
                returnString = albumName
            }
            
            if let callback, let returnString {
                callback(returnString)
            }
        }
        createAlbumAlert.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("kCANCEL", comment: "Cancel"), style: .cancel, handler: nil)
        createAlbumAlert.addAction(cancelAction)

        self.present(createAlbumAlert, animated: true, completion: nil)
    }
    
    private func setupViews() {
        self.view = screenView
		
		self.screenView.galleriesCollectionView.delegate = self
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: screenView.closeButton)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: screenView.rightBarButton)
		self.navigationItem.title = NSLocalizedString("kSELECTLIBRARY", comment: "Select library to load")
    }
}

extension SelectLibraryViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: nil,
										  previewProvider: nil,
										  actionProvider: { [weak self]
			suggestedActions in
			let deleteAction =
			UIAction(title: NSLocalizedString("kDELETEGALLERY", comment: ""),
					 image: UIImage(systemName: "trash"), attributes: [.destructive]) { action in
				if let galleryName = self?.dataSource?[indexPath].mainGalleryName {
					self?.viewModel.delete(gallery: galleryName)
				}
			}
			let renameAction =
			UIAction(title: NSLocalizedString("kRenameAlbum", comment: ""),
					 image: UIImage(systemName: "pencil")) { action in
				
				if let galleryIndex = self?.dataSource?[indexPath] {
					self?.showCreateLibraryDialog(withPrepulatedName: galleryIndex.mainGalleryName, callback: { newName in
						self?.viewModel.rename(gallery: galleryIndex, withName: newName)
					})
				}
			}
			return UIMenu(title: "", children: [renameAction, deleteAction])
		})
	}
}
