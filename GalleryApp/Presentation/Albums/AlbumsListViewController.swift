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

    // MARK: - Properties
    var container: Container!
    var galleryManager: GalleryManager
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSections, SidebarItem>!
    private var collectionView: UICollectionView!
    private var screens: [String: UIViewController]
    var albums = [SidebarItem]()
    var selectedAlbum: UUID?
    var selectedImages: [String]
    var mainButtonsRX = PublishSubject<[SidebarItem]>()
    var albumRX = PublishSubject<[SidebarItem]>()
    var albumsSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
    let disposeBag = DisposeBag()
    
    
    // MARK: - Init
    init(galleryInteractor: GalleryManager, container: Container, selectedImages: [String]) {
        self.galleryManager = galleryInteractor
        self.selectedImages = selectedImages
        self.container = container
        screens = ["allPhotos": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!),
                   "search": UINavigationController(rootViewController: container.resolve(AlbumScreenViewController.self)!)]
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveToAlbum(images: [String], album: UUID) {
        do {
            try self.galleryManager.move(Image: AlbumImage(fileName: images.first!, date: Date()), toAlbum: album) {
                self.dismiss(animated: true)
            }
        } catch MoveImageError.imageAlreadyInAlbum {
            let imageAlreadyInAlbumString = NSLocalizedString("kImageAlreadyInAlbum", comment: "")
            let UIAlert = UIAlertController(title: NSLocalizedString("kCantAddImageToTheAlbum", comment: ""), message: imageAlreadyInAlbumString, preferredStyle: .alert)
            let OKButton = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .default) { UIAlertAction in
                self.dismiss(animated: true)
            }
            UIAlert.addAction(OKButton)
            self.present(UIAlert, animated: true)
        } catch {
            self.dismiss(animated: true)
        }
        
    }
    
    // MARK: - Data Binding
    func bindAlbums() {
        let index: GalleryIndex? = self.galleryManager.loadGalleryIndex()
        
        if let index = index {
            self.albums = index.albums.compactMap { albumID in
                if let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
                    return SidebarItem(from: albumIndex)
                }
                return nil
            }
        }
        
        self.galleryManager.selectedGalleryIndexRelay.subscribe(onNext: { gallery in
            self.albums = gallery.albums.compactMap { albumID in
                if let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
                    return SidebarItem(from: albumIndex)
                }
                return nil
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Lifecycle
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
        selectAlbum.setTitle(NSLocalizedString("kSELECTALBUM", comment: ""), for: .normal)
        selectAlbum.tintColor = .systemBlue
        selectAlbum.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        selectAlbum.rx.tap.subscribe(onNext: { [weak self] in
            if let selectedAlbum = self?.selectedAlbum, let selectedImages = self?.selectedImages {
                self?.moveToAlbum(images: selectedImages, album: selectedAlbum)
            }
        }).disposed(by: disposeBag)
        
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

        dataSource = UICollectionViewDiffableDataSource<SidebarSections, SidebarItem>(collectionView: collectionView) {
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
            self.dataSource.apply(sectionSnapshot, to: .mainButtons)
        }).dispose()

        bindAlbums()
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
        
        dataSource = UICollectionViewDiffableDataSource<SidebarSections, SidebarItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: SidebarItem) -> UICollectionViewCell? in
            if indexPath.item == 0 && indexPath.section != 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
    }
}

extension AlbumsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(albums[indexPath.row].title ?? "")
        self.selectedAlbum = albums[indexPath.row].identifier
    }
}

