//
//  SelectLibraryViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.04.2023.
//

import Foundation
import UIKit
import RxDataSources
import RxSwift

class SelectLibraryViewController: UIViewController {
    
    // MARK: - Views
    let screenView = SelectLibraryView()
    let viewModel: SelectLibraryViewModel
	let pathResolver: PathResolver
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
        self.layoutViews()
        self.bindInteractions()
        self.bindData()
    }
    
    func bindData() {
		self.viewModel.loadGalleriesAsObservable()
			.bind(to: screenView.galleriesCollectionView.rx.items(dataSource: dataSource!))
			.disposed(by: disposeBag)
		
		self.viewModel.loadCurrentGalleryAsObservable().subscribe(onNext: { index in
			if let indexPath = self.dataSource?.sectionModels.first?.items.firstIndex(where: { galleryIndex in
				galleryIndex.mainGalleryName == index.mainGalleryName
			}) {
				self.screenView.galleriesCollectionView.selectItem(at: IndexPath(row: indexPath, section: 0), animated: false, scrollPosition: .bottom)
			}
		}).disposed(by: disposeBag)
    }
    
    func bindInteractions() {
        self.screenView.galleriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] index in
            guard let self else { return }
            if let libraryName = self.dataSource?.sectionModels.first?.items[index.item] {
				self.viewModel.switchTo(library: libraryName.mainGalleryName)
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
            if let galleryName = self?.dataSource?.sectionModels.first?.items[index.row] {
				self?.viewModel.delete(gallery: galleryName.mainGalleryName)
            }
        }
    }
    
    func configureDataSource() {
		self.dataSource = RxCollectionViewSectionedAnimatedDataSource<SelectLibraryAnimatableSectionModel>(configureCell: { [weak self] dataSource, collectionView, indexPath, item in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarViewCell.identifier, for: indexPath) as! SidebarViewCell
			cell.label.text = item.mainGalleryName
			if let lastGalleryImage = item.images.first, let thumbnailImagePath = self?.pathResolver.resolveThumbPathFor(imageName: lastGalleryImage.fileName) {
				cell.imageView.image = UIImage(contentsOfFile: thumbnailImagePath)
			}
			return cell})
    }
    
    // MARK: - Create Album Popover Dialog Box
    @objc func showCreateLibraryDialog(withPrepulatedName: String? = nil, callback: ((String) -> Void)? = nil) {
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
                
                let noAlbumAlert = UIAlertController(title: NSLocalizedString("kAlbumNameCantBeEmpty", comment: ""), message: nil, preferredStyle: .alert)
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
    
    func setupViews() {
        self.view = screenView
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: screenView.closeButton)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: screenView.rightBarButton)
		self.navigationItem.title = NSLocalizedString("kSELECTLIBRARY", comment: "Select library to load")
    }
    
    func layoutViews() {
        
    }
}
