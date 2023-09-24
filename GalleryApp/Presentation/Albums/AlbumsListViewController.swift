//
//  SidebarViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import RxDataSources
import Swinject
import DirectoryWatcher

class AlbumsListViewController: UIViewController {
    
    // MARK: - Properties
    var container: Container!
    var galleryManager: GalleryManager
    private var dataSource: RxCollectionViewSectionedReloadDataSource<SidebarSection>?
    var albums = [SidebarItem]()
    var selectedAlbum: UUID?
    var selectedImages: [AlbumImage]
    let router: AlbumListRouter
    let viewModel: AlbumListViewModel
    let screenView = AlbumsListView()
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(galleryInteractor: GalleryManager, container: Container, selectedImages: [AlbumImage], router: AlbumListRouter) {
        self.galleryManager = galleryInteractor
        self.selectedImages = selectedImages
        self.container = container
        self.viewModel = AlbumListViewModel(galleryManager: galleryManager)
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        screenView.albumsCollectionView.delegate = self
        screenView.albumsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        self.router.start(viewController: self)
        
        setupViews()
        configureDataSource()
        bindAlbums()
        bindInteractions()
        bindAlert()
        bindDissmisal()
    }
    
    func bindAlert() {
        self.viewModel.showErrorCantAddImageToAlbum.distinctUntilChanged().subscribe(onNext: { value in
            if value {
                let imageAlreadyInAlbumString = NSLocalizedString("kImageAlreadyInAlbum", comment: "")
                let UIAlert = UIAlertController(title: NSLocalizedString("kCantAddImageToTheAlbum", comment: ""), message: imageAlreadyInAlbumString, preferredStyle: .alert)
                let OKButton = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .default) { UIAlertAction in
                    self.dismiss(animated: true)
                }
                UIAlert.addAction(OKButton)
                self.present(UIAlert, animated: true)
            }
        }).disposed(by: disposeBag)
    }
    
    func bindDissmisal() {
        self.viewModel.shouldDismiss.subscribe(onNext: { [weak self] value in
            if value {
                self?.dismiss(animated: false)
            }
        }).disposed(by: disposeBag)
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
        
        self.viewModel.fetchAlbums()
            .bind(to: self.screenView.albumsCollectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
    }
    
    @objc func closeWindow(sender: Any) {
        self.dismiss(animated: true)
    }
    
    func bindInteractions() {
        // MARK: - Select Album tapped button interaction
        self.screenView.selectAlbumButton.rx.tap.subscribe(onNext: { [weak self] in
            if let selectedAlbum = self?.selectedAlbum, let selectedImages = self?.selectedImages {
                self?.viewModel.moveToAlbum(images: selectedImages, album: selectedAlbum)
            }
        }).disposed(by: disposeBag)
        
        self.navigationItem.leftBarButtonItem?.rx.tap.subscribe(onNext: { [weak self] in
            self?.router.onCancelTap()
        }).disposed(by: disposeBag)
        
        self.screenView.albumsCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            self?.screenView.selectAlbumButton.isEnabled = true
        }).disposed(by: disposeBag)
    }
    
    func setupViews() {
        view = screenView
        
        self.navigationItem.title = NSLocalizedString("kSelectDestination", comment: "")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.screenView.selectAlbumButton)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: nil)
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        self.screenView.albumsCollectionView.register(SidebarCell.self, forCellWithReuseIdentifier: SidebarCell.identifier)
        self.screenView.selectAlbumButton.isEnabled = false
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
        
        dataSource = RxCollectionViewSectionedReloadDataSource<SidebarSection>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarCell.identifier, for: indexPath) as! SidebarCell
                cell.textView.text = item.title
                cell.imageView.image = item.image
                if item.type == .allPhotos {
                    cell.imageView.contentMode = .scaleAspectFit
                } else {
                    cell.imageView.contentMode = .scaleAspectFill
                }
                return cell
            }
        )
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.router.onCancelTap()
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


