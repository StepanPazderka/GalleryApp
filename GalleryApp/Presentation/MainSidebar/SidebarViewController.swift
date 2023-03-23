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
import DirectoryWatcher

class SidebarViewController: UIViewController {
    
    // MARK: - Views
    let screenView = SidebarView()
    
    // MARK: - Properties
    private var dataSource: RxCollectionViewSectionedReloadDataSource<SidebarSection>?
    let router: SidebarRouter
    var screens: [String: UIViewController]

    let viewModel: SidebarViewModel
        
    let disposeBag = DisposeBag()

    // MARK: - Sidebar Snapshots
    var mainButtonsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    var albumsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    var smartAlbumsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    
    // MARK: - Init
    init(router: SidebarRouter, container: Container, viewModel: SidebarViewModel) {
        screens = ["allPhotos": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!),
                   "search": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!)]
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

        self.router.showAllPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        screenView.layoutViews()
    }
    
    // MARK: - Create Album Popover
    @objc func showRenameAlbumDialog(withPrepulatedName: String? = nil, callback: ((String) -> Void)? = nil) {
        var returnString: String?
        let createAlbumAlert = UIAlertController(title: NSLocalizedString("kEnterAlbumName", comment: ""), message: nil, preferredStyle: .alert)

        createAlbumAlert.addTextField { textField in
            textField.placeholder = "Album name"
            
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

        let cancelAction = UIAlertAction(title: NSLocalizedString("kCANCEL", comment: ""), style: .cancel, handler: nil)
        createAlbumAlert.addAction(cancelAction)

        self.present(createAlbumAlert, animated: true, completion: nil)
    }
    
    // MARK: - Data Binding
    private func bindData() {
        viewModel.loadGalleryName()
            .asDriver(onErrorJustReturn: "")
            .drive(self.screenView.selectGalleryButton.rx.title())
            .disposed(by: disposeBag)
    
        viewModel.loadSidebarContent()
            .bind(to: screenView.sidebarCollectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
    }
    
    // MARK: - User Interaction Bindings
    func bindInteractions() {
        self.screenView.selectGalleryButton.rx.tap.subscribe(onNext: { [weak self] in
            let newController = UIViewController()
            newController.view.backgroundColor = .systemBackground
            self?.present(newController, animated: true, completion: nil)
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
    func setupViews() {
        self.view = screenView
        
        view.addSubviews(self.screenView.sidebarCollectionView)
        
        self.screenView.sidebarCollectionView.delegate = self
        self.screenView.sidebarCollectionView.translatesAutoresizingMaskIntoConstraints = true
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.titleView = self.screenView.selectGalleryButton
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: screenView.addAlbumButton)
    }
    
    // MARK: - Data Source Configuration
    func configureDataSource() {
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { (headerView, elementKind, indexPath) in
            if let category = self.dataSource?[indexPath.section].category {
                var content = headerView.defaultContentConfiguration()
                content.text = category
                headerView.contentConfiguration = content
            }
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = item.image
            cell.contentConfiguration = content
            cell.accessories = []
        }
        
        dataSource = RxCollectionViewSectionedReloadDataSource<SidebarSection>(
            configureCell: { dataSource, collectionView, indexPath, item in
                // Use content cell registration for all other items
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
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
            let renameAction =
            UIAction(title: NSLocalizedString("kRenameAlbum", comment: ""),
                     image: UIImage(systemName: "pencil")) { action in
                
                if let albumName = self.dataSource?[indexPath].title, let albumID = self.dataSource?[indexPath].identifier {
                    self.showRenameAlbumDialog(withPrepulatedName: albumName) { [indexPath] newAlbumName in
                        self.viewModel.renameAlbum(id: albumID, withNewAlbumName: newAlbumName)
                        self.screenView.sidebarCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
                    }
                }
            }
            return UIMenu(title: "", children: [renameAction, inspectAction, duplicateAction, deleteAction])
        })
    }
}

extension SidebarViewController: UIImagePickerControllerDelegate {
    
}
