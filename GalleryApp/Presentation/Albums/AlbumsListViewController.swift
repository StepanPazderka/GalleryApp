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
//    var container: Container!
    private var dataSource: RxCollectionViewSectionedReloadDataSource<SidebarSection>?
    var selectedAlbum: UUID?
    var selectedImages: [GalleryImage]
    private let router: AlbumListRouter
    public let viewModel: AlbumsListViewModel
    let screenView = AlbumsListView()
    let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(selectedImages: [GalleryImage], router: AlbumListRouter, viewModel: AlbumsListViewModel) {
        self.selectedImages = selectedImages
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.router.start(viewController: self)
        
        self.setupViews()
        self.configureDataSource()
        self.bindData()
        self.bindInteractions()
        self.bindDissmisal()
    }
    
    func bindDissmisal() {
        self.viewModel.shouldDismiss.subscribe(onNext: { [weak self] value in
            if value {
                self?.dismiss(animated: false)
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Data Binding
    func bindData() {
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
        
        self.viewModel.fetchAlbums()
            .bind(to: self.screenView.albumsCollectionView.rx.items(dataSource: dataSource!))
            .disposed(by: disposeBag)
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
        
        self.screenView.albumsCollectionView.rx.modelSelected(SidebarItem.self).subscribe(onNext: { [weak self] item in
            self?.selectedAlbum = item.identifier
        }).disposed(by: disposeBag)
    }
    
    func setupViews() {
        view = screenView
        
        self.navigationItem.title = NSLocalizedString("kSelectDestination", comment: "")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.screenView.selectAlbumButton)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: nil)
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        self.screenView.albumsCollectionView.register(SidebarViewCell.self, forCellWithReuseIdentifier: SidebarViewCell.identifier)
        self.screenView.selectAlbumButton.isEnabled = false
    }
    
    // MARK: - Data Source Configuration
    func configureDataSource() {
        dataSource = RxCollectionViewSectionedReloadDataSource<SidebarSection>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SidebarViewCell.identifier, for: indexPath) as! SidebarViewCell
                cell.label.text = item.title
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


