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
import SnapKit
import RxDataSources
import Swinject
import DirectoryWatcher

enum MainScreens: String, CaseIterable {
    case allPhotos
}

class SidebarViewController: UIViewController, UINavigationControllerDelegate, UISplitViewControllerDelegate {
    
    // MARK: -- Views
    let screenView = SidebarView()
    
    // MARK: -- Properties
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    private var secondaryViewControllers: [UIViewController] = []
    let router: SidebarRouter
    var screens: [String: UIViewController]
    var mainbuttons: [SidebarItem] {
        get {
            [SidebarItem(id: UUID(), title: "All Photos", image: UIImage(systemName: "photo.on.rectangle.angled")),
             SidebarItem(id: UUID(), title: "Radio", image: UIImage(systemName: "dot.radiowaves.left.and.right")),
             SidebarItem(id: UUID(), title: "Search", image: UIImage(systemName: "magnifyingglass"))]
        }
    }
    let smartalbums = [SidebarItem(id: UUID(), title: "Smart Albums", image: UIImage(systemName: "music.note.list")),
                       SidebarItem(id: UUID(), title: "Replay 2015", image: UIImage(systemName: "folder.badge.gearshape")),
                       SidebarItem(id: UUID(), title: "Replay 2016", image: UIImage(systemName: "music.note.list")),
                       SidebarItem(id: UUID(), title: "Replay 2017", image: UIImage(systemName: "music.note.list")),
                       SidebarItem(id: UUID(), title: "Replay 2018", image: UIImage(systemName: "music.note.list")),
                       SidebarItem(id: UUID(), title: "Replay 2019", image: UIImage(systemName: "music.note.list"))]

    let viewModel: SidebarViewModel
    let disposeBag = DisposeBag()
    
    // MARK: -- Sidebar Snapshots
    var mainButtonsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    var albumsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    var smartAlbumsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    
    // MARK: -- Init
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
    
    // MARK: -- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.bindData()
        self.bindInteractions()

        ConfigureDataSource()
        router.showAllPhotos()
        
        self.viewModel.fetchAlbumButtons().subscribe(onNext: { albumButtons in
            self.viewModel.albumButtons = albumButtons
        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.addSubview(self.screenView.sidebarMenu)
        screenView.layoutViews()
    }
    
    // MARK: -- Create Album Popover
    @objc func showCreateAlbumPopover() {
        let createAlbumAlert = UIAlertController(title: NSLocalizedString("kEnterAlbumName", comment: ""), message: nil, preferredStyle: .alert)

        createAlbumAlert.addTextField { textField in
            textField.placeholder = "Album name"
        }
                
        let confirmAction = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .default) { [weak createAlbumAlert] _ in
            guard let alertController = createAlbumAlert, let textField = alertController.textFields?.first, let text = textField.text else { return }
            
            if text.isEmpty {
                let okAction = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .destructive)
                
                let noAlbumAlert = UIAlertController(title: NSLocalizedString("kAlbumNameCantBeEmpty", comment: ""), message: nil, preferredStyle: .alert)
                noAlbumAlert.addAction(okAction)
                self.present(noAlbumAlert, animated: true)
                return
            }
            
            if let albumName = textField.text, !text.isEmpty {
                self.viewModel.createAlbum(name: albumName, callback: {
                    self.viewModel.loadAlbums()
                    self.refreshMenu()
                    self.refreshAlbums()
                })
            }
        }
        createAlbumAlert.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("kCANCEL", comment: ""), style: .cancel, handler: nil)
        createAlbumAlert.addAction(cancelAction)

        self.present(createAlbumAlert, animated: true, completion: nil)
    }
    
    // MARK: - Data Binding
    private func bindData() {
        viewModel.fetchAlbumButtons().subscribe(onNext: { [weak self] albumButtons in
            self?.viewModel.albumButtons = albumButtons
        }).disposed(by: disposeBag)
        
        viewModel.loadGalleryName()
            .asDriver(onErrorJustReturn: "")
            .drive(self.screenView.selectGalleryButton.rx.title())
            .disposed(by: disposeBag)
        
        viewModel.galleryIndex().subscribe(onNext: { galleryIndex in
            self.refreshAlbums()
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Interaction Bindings
    func bindInteractions() {
        self.screenView.selectGalleryButton.rx.tap.subscribe(onNext: { [weak self] in
            let newController = UIViewController()
            newController.view.backgroundColor = .systemBackground
            self?.present(newController, animated: true, completion: nil)
        }).disposed(by: disposeBag)

        self.screenView.addAlbumButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.showCreateAlbumPopover()
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Setup
    func setupViews() {
        self.view = screenView
        
        self.screenView.sidebarMenu.delegate = self
        self.screenView.sidebarMenu.translatesAutoresizingMaskIntoConstraints = false
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.titleView = self.screenView.selectGalleryButton
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: screenView.addAlbumButton)
    }

    func ConfigureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure()]
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.image = item.image?.roundedImage
            cell.contentConfiguration = content
            cell.accessories = []
        }
        
        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: self.screenView.sidebarMenu) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: SidebarItem) -> UICollectionViewCell? in
            if indexPath.item == 0 && indexPath.section != 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }

        refreshMenu()
    }

    func refreshMenu() {
        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        snapshot.appendSections(SidebarSection.allCases)
        dataSource.apply(snapshot, animatingDifferences: true)
        
        for section in SidebarSection.allCases {
            switch section {
            case .mainButtons:
                refreshMainButtons()
            case .smartAlbumsButtons:
                refreshSmartAlbums()
            case .albumsButtons:
                refreshAlbums()
            }
        }
    }
    
    func refreshMainButtons() {
        mainButtonsSnapshot.deleteAll()
        mainButtonsSnapshot.append(mainbuttons)
        dataSource.apply(mainButtonsSnapshot, to: .mainButtons, animatingDifferences: true)
    }
    
    func refreshSmartAlbums() {
        let headerItem = SidebarItem(id: UUID(), title: SidebarSection.smartAlbumsButtons.rawValue, image: nil)
        smartAlbumsSnapshot.deleteAll()
        smartAlbumsSnapshot.append([headerItem])
        smartAlbumsSnapshot.append(smartalbums, to: headerItem)
        smartAlbumsSnapshot.append([SidebarItem(id: UUID(), title: "Test", image: UIImage(systemName: "folder.badge.gearshape"))], to: smartalbums[1])
        smartAlbumsSnapshot.expand([smartalbums[1]])
        smartAlbumsSnapshot.expand([headerItem])
        dataSource.apply(smartAlbumsSnapshot, to: .smartAlbumsButtons)
    }
    
    func refreshAlbums() {
        let headerItem = SidebarItem(id: UUID(), title: SidebarSection.albumsButtons.rawValue, image: nil)
        albumsSnapshot.deleteAll()
        albumsSnapshot.append([headerItem])
        albumsSnapshot.append(viewModel.albumButtons, to: headerItem)
        albumsSnapshot.expand([headerItem])
        dataSource.apply(albumsSnapshot, to: .albumsButtons, animatingDifferences: true)
    }
}

extension SidebarViewController: UICollectionViewDelegate {

    // -- MARK: Selected
    // User Selected Item in Sidebar
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            router.showAllPhotos()
        }
        
        if indexPath.section == 1 {
            let albumID = self.viewModel.albumButtons[indexPath.row-1].identifier
            router.show(album: albumID)
        }
    }
    
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
            UIAction(title: NSLocalizedString("DUPLICATEALBUM", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                //                self.performDuplicate(indexPath)
            }
            let deleteAction =
            UIAction(title: NSLocalizedString(kDeleteAlbum, comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                self.viewModel.deleteAlbum(index: indexPath.row) {
                    self.viewModel.loadAlbums()
                    self.refreshAlbums()
                    self.refreshMenu()
                }
            }
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }
}

extension SidebarViewController: UIImagePickerControllerDelegate {
    
}
