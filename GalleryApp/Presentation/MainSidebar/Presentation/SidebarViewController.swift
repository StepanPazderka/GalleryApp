//
//  SidebarViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit
import UniformTypeIdentifiers
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import Swinject

class SidebarViewController: UIViewController {
    
    // MARK: - Views
    let screenView = SidebarView()
    
    // MARK: - Properties
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<SidebarSectionModel>?
    private let router: SidebarRouter
    private let viewModel: SidebarViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(router: SidebarRouter, container: Container, viewModel: SidebarViewModel) {
        self.router = router
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureDataSource()
        
        self.setupViews()
        self.bindData()
        self.bindInteractions()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.screenView.layoutViews()
    }
    
    // MARK: - Create Album Popover
    @objc func showRenameAlbumDialog(withPrepopulatedName: String? = nil, callback: ((String) -> Void)? = nil) {
        var returnString: String?
        let createAlbumAlert = UIAlertController(title: NSLocalizedString("kEnterAlbumName", comment: ""), message: nil, preferredStyle: .alert)
        
        createAlbumAlert.addTextField { textField in
            textField.placeholder = "Album name"
            
            if let withPrepopulatedName {
                textField.text = withPrepopulatedName
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
    
    // MARK: - Data Binding
    private func bindData() {
        viewModel.getSelectedLibraryNameAsObservable()
            .asDriver(onErrorJustReturn: "")
            .drive(self.screenView.selectGalleryButton.rx.title())
            .disposed(by: disposeBag)
        
        viewModel.loadSidebarContent()
            .bind(to: screenView.sidebarCollectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
        
        viewModel.getSelectedLibraryNameAsObservable()
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] libraryName in
				self.router.showAllPhotos()
				self.screenView.sidebarCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .bottom)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - User Interaction Bindings
    func bindInteractions() {
        self.screenView.selectGalleryButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.router.showLibrarySelectionScreen()
        }).disposed(by: disposeBag)
        
        self.screenView.addAlbumButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.showRenameAlbumDialog() { newAlbumName in
                self?.viewModel.createAlbum(name: newAlbumName)
            }
        }).disposed(by: disposeBag)
        
        self.screenView.sidebarCollectionView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                let item = self.dataSource![indexPath]
                if item.type == .album {
                    self.router.show(album: item.identifier!)
                } else if item.type == .allPhotos {
                    self.router.showAllPhotos()
                }
                // Deselect the previously selected cell, if any
                if let selectedIndexPath = self.screenView.sidebarCollectionView.indexPathsForSelectedItems?.first {
                    self.screenView.sidebarCollectionView.deselectItem(at: selectedIndexPath, animated: true)
                }
                
                // Select the newly selected cell
                self.screenView.sidebarCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Views Setup
    private func setupViews() {
        self.view = screenView
        
        self.screenView.sidebarCollectionView.register(SidebarViewCell.self, forCellWithReuseIdentifier: SidebarViewCell.identifier)
        
        self.screenView.sidebarCollectionView.delegate = self

        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.titleView = self.screenView.selectGalleryButton
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: screenView.addAlbumButton)
    }
    
    // MARK: - Data Source Configuration
    func configureDataSource() {
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in
            if let category = self.dataSource?[indexPath.section].name {
                var content = headerView.defaultContentConfiguration()
                content.text = category
                headerView.contentConfiguration = content
            }
        }
        
        dataSource = RxCollectionViewSectionedAnimatedDataSource<SidebarSectionModel>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarViewCell.identifier, for: indexPath) as! SidebarViewCell
                cell.label.text = item.title
                cell.imageView.image = item.image
                if item.image == nil {
                    cell.imageView.image = UIImage(named: "rectangle")
                }
                if item.type == .allPhotos {
                    cell.imageView.contentMode = .scaleAspectFit
                } else {
                    cell.imageView.contentMode = .scaleAspectFill
                }
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard kind == UICollectionView.elementKindSectionHeader else {
                    fatalError("Unexpected supplementary view kind: \(kind)")
                }
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }
        )
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("CreateSubAlbum", comment: ""),
                     image: UIImage(systemName: "plus.square")) { action in
                
            }
            let duplicateAction =
            UIAction(title: NSLocalizedString("kDUPLICATEALBUM", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                if let albumId = self.dataSource?[indexPath].identifier {
                    self.viewModel.duplicateAlbum(id: albumId)
                }
                
            }
            let deleteAction =
            UIAction(title: NSLocalizedString(kDeleteAlbum, comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                if let albumId = self.dataSource?[indexPath].identifier {
                    self.viewModel.deleteAlbum(id: albumId)
                }
            }
            let removeThumbnail =
            UIAction(title: NSLocalizedString(kRemoveThumbnail, comment: ""),
                     image: UIImage(systemName: "square.slash")) { action in
                if let albumID = self.dataSource?[indexPath].identifier {
                    self.viewModel.removeThumbnail(albumID: albumID)
                }
            }
            let renameAction =
            UIAction(title: NSLocalizedString("kRenameAlbum", comment: ""),
                     image: UIImage(systemName: "pencil")) { action in
                
                if let albumName = self.dataSource?[indexPath].title, let albumID = self.dataSource?[indexPath].identifier {
                    self.showRenameAlbumDialog(withPrepopulatedName: albumName) { [indexPath] newAlbumName in
                        do {
                            try self.viewModel.renameAlbum(id: albumID, withNewAlbumName: newAlbumName)
                        } catch {
                            print(error)
                        }
                        self.screenView.sidebarCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                    }
                }
            }
            return UIMenu(title: "", children: [renameAction, inspectAction, removeThumbnail, duplicateAction, deleteAction])
        })
    }
}
