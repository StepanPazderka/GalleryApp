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

class AlbumsListViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISplitViewControllerDelegate {

    // MARK: - Properties
    var container: Container!
    var galleryManager: GalleryManager
    private var dataSource: RxCollectionViewSectionedReloadDataSource<SidebarSection>?
    private var collectionView: UICollectionView!
    var albums = [SidebarItem]()
    var selectedAlbum: UUID?
    var selectedImages: [String]
    let viewModel: AlbumListViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(galleryInteractor: GalleryManager, container: Container, selectedImages: [String]) {
        self.galleryManager = galleryInteractor
        self.selectedImages = selectedImages
        self.container = container
        self.viewModel = AlbumListViewModel(galleryManager: galleryManager)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.viewModel.fetchAlbums().bind(to: self.collectionView.rx.items(dataSource: dataSource!)).disposed(by: disposeBag)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let selectAlbumButton = UIButton(type: .system)
        selectAlbumButton.setTitle(NSLocalizedString("kSELECTALBUM", comment: ""), for: .normal)
        selectAlbumButton.tintColor = .systemBlue
        selectAlbumButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        selectAlbumButton.rx.tap.subscribe(onNext: { [weak self] in
            if let selectedAlbum = self?.selectedAlbum, let selectedImages = self?.selectedImages {
                self?.viewModel.moveToAlbum(images: selectedImages, album: selectedAlbum)
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectAlbumButton)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(closeWindow))
        navigationController?.navigationBar.prefersLargeTitles = false

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: self.createLayout())
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false // This line fixes issue with incorrect highlighting
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }

        configureDataSource()
        bindAlbums()
        bindAlert()
        bindDissmisal()
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
            if item.type == .album {
                content.image = item.image?.resized(to: CGSize(width: 25, height: 25))
            } else {
                content.image = item.image
            }
            
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

extension AlbumsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(albums[indexPath.row].title ?? "")
        self.selectedAlbum = albums[indexPath.row].identifier
    }
}

