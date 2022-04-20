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

class AlbumsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISplitViewControllerDelegate {
    
    var container: Container!
    var galleryInteractor: GalleryManager
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    private var collectionView: UICollectionView!
    private var secondaryViewControllers: [UIViewController] = []
    let disposeBag = DisposeBag()

    let router = SidebarRouter()
    
    var screens: [String: UIViewController]
    
    var mainbuttons: [SidebarItem] {
        get {
            [SidebarItem(title: "All Photos", image: UIImage(systemName: "photo.on.rectangle.angled")),
             SidebarItem(title: "Radio", image: UIImage(systemName: "dot.radiowaves.left.and.right")),
             SidebarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"))]
        }
    }
    
    var albums: [SidebarItem] {
        get {
            galleryInteractor.listAlbums(url: nil).map { album in
                SidebarItem(title: album.name, image: UIImage(contentsOfFile: galleryInteractor.selectedGalleryPath.appendingPathComponent(album.thumbnail).relativePath)?.resized(to: CGSize(width: 30, height: 30)))
            }
        }
        
        set {
            self.refreshMenu()
        }
    }
    
    var mainButtonsRX = PublishSubject<[SidebarItem]>()
    var albumRX = PublishSubject<[SidebarItem]>()
    
    init(galleryInteractor: GalleryManager, container: Container) {
        self.galleryInteractor = galleryInteractor
        self.container = container
        screens = ["allPhotos": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!),
                   "search": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!)]
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showCreateAlbumPopover() {
        let alertController = UIAlertController(title: "Enter Album name", message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Album name"
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            if let albumName = alertController.textFields?.first?.text {
                try! self.galleryInteractor.createAlbum(name: albumName)
                self.albums.append(SidebarItem(title: albumName, image: nil))
            }
        }
        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        let selectAlbum = UIButton(type: .system)
//        selectAlbum.setImage(UIImage(systemName: "plus"), for: .normal)
        selectAlbum.setTitle("Select Album", for: .normal)
        selectAlbum.tintColor = .systemBlue
        selectAlbum.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        selectAlbum.rx.tap.subscribe(onNext: { [weak self] in
            self?.showCreateAlbumPopover()
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        
        navigationItem.title = "Hey"
        let selectGalleryButton: UIButton = { let view = UIButton()
            view.setTitle("Hey", for: .normal)
            view.setTitleColor(.label, for: .normal)
            view.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
            return view
        }()
        
        selectGalleryButton.rx.tap.subscribe(onNext: { [weak self] in
            let newController = UIViewController()
            newController.view.backgroundColor = .systemBackground
            self?.present(newController, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
//        navigationItem.titleView = selectGalleryButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectAlbum)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: nil, action: nil)
        navigationController?.navigationBar.prefersLargeTitles = false

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: self.createLayout())
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false // This line fixes issue with incorrect highlighting
        view.addSubview(collectionView)

        // MARK: -- Snapkit Example
        collectionView.snp.makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
                
        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: SidebarItem) -> UICollectionViewCell? in
            if indexPath.item == 0 && indexPath.section != 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
        
        mainButtonsRX.subscribe(onNext: { mainButtons in
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
            sectionSnapshot.append(mainButtons)
            self.dataSource.apply(sectionSnapshot, to: .tabs)
        }).dispose()
        
        ConfigureDataSource()
        
        collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
        splitViewController?.setViewController(UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!), for: .secondary)
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }
    
    func displayAlbums() {
        let sections: [SidebarSection] = [.tabs, .albums, .smartAlbums]
        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        snapshot.appendSections(sections)
        
        let headerItem = SidebarItem(title: SidebarSection.albums.rawValue, image: nil)
        var albumsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        albumsSnapshot.append([headerItem])
        albumsSnapshot.append(albums, to: headerItem)
        albumsSnapshot.expand([headerItem])
        self.dataSource.apply(albumsSnapshot, to: .albums)
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
        
        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) {
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
        let sections: [SidebarSection] = [.albums]
        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: true)
        
        for section in sections {
            let headerItem = SidebarItem(title: section.rawValue, image: nil)
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
            sectionSnapshot.append([headerItem])
            sectionSnapshot.append(albums, to: headerItem)
            sectionSnapshot.expand([headerItem])
            dataSource.apply(sectionSnapshot, to: section)
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
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                //                self.performDuplicate(indexPath)
            }
            let deleteAction =
            UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                if let albumName = self.albums[indexPath.item-1].title {
                    self.galleryInteractor.removeAlbum(AlbumName: albumName)
                }
            }
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }
}

extension AlbumsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let albumName = mainbuttons[indexPath.row].title
            splitViewController?.setViewController(screens.first(where: { $0.key == "allPhotos"})?.value, for: .secondary)
        }
        
        if indexPath.section == 1 {
            if let albumName = albums[indexPath.row-1].title {
                splitViewController?.setViewController(UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self, argument: albumName)!), for: .secondary)
            }
        }
    }
}

