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
import RxDataSources
import Swinject
import DirectoryWatcher

class AlbumsListViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISplitViewControllerDelegate {
    
    var container: Container!
    var galleryInteractor: GalleryManager
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    private var collectionView: UICollectionView!
    private var secondaryViewControllers: [UIViewController] = []
    let disposeBag = DisposeBag()

//    let router = SidebarRouter()
    
    var screens: [String: UIViewController]
    
    var albums: [SidebarItem] {
        get {
            galleryInteractor.scanFolderForAlbums(url: nil).map { album in
                SidebarItem(id: album.id, title: album.name, image: UIImage(contentsOfFile: galleryInteractor.selectedGalleryPath.appendingPathComponent(album.thumbnail).relativePath)?.resized(to: CGSize(width: 30, height: 30)))
            }
        }
        
        set {
            self.refreshMenu()
        }
    }
    
    var selectedAlbum: String?
    var selectedImages: [String]
    
    var mainButtonsRX = PublishSubject<[SidebarItem]>()
    var albumRX = PublishSubject<[SidebarItem]>()
    
    init(galleryInteractor: GalleryManager, container: Container, selectedImages: [String]) {
        self.galleryInteractor = galleryInteractor
        self.selectedImages = selectedImages
        self.container = container
        screens = ["allPhotos": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!),
                   "search": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!)]
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveToAlbum(images: [String], album: String) {
        
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
            if let selectedAlbum = self?.selectedAlbum, let selectedImages = self?.selectedImages {
                self?.moveToAlbum(images: selectedImages, album: selectedAlbum)
            }
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectAlbum)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(closeWindow))
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
    }
    
    @objc func closeWindow(sender: Any) {
        self.dismiss(animated: true)
    }

    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
            config.headerMode = section == 0 ? .none : .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
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
        dataSource.apply(snapshot, animatingDifferences: true)
        
        for section in sections {
            let headerItem = SidebarItem(id: UUID(), title: sections.first?.rawValue, image: nil)
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
            sectionSnapshot.append(albums)
            dataSource.apply(sectionSnapshot, to: section)
        }
    }
}

extension AlbumsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(albums[indexPath.row].title ?? "")
        self.selectedAlbum = albums[indexPath.row].title
    }
}
