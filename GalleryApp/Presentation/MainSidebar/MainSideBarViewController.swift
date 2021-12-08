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

enum SidebarSection: String {
    case tabs
    case albums = "Albums"
    case playlists = "Playlists"
}

struct SidebarItem: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()

    internal init(title: String?, image: UIImage?) {
        self.title = title
        self.image = image
    }

    init?(from: AlbumIndex) {
        self.title = from.name
        let thumbnailImage: UIImage? = UIImage(contentsOfFile: IndexInteractor.documentDirectory.appendingPathComponent(from.thumbnail).relativePath)?.resized(to: CGSize(width: 30, height: 30))
        self.image = thumbnailImage
    }
}

let tabsItems = [SidebarItem(title: "All Photos", image: UIImage(systemName: "photo.on.rectangle.angled")),
                 SidebarItem(title: "Import photo", image: UIImage(systemName: "square.grid.2x2")),
                 SidebarItem(title: "Radio", image: UIImage(systemName: "dot.radiowaves.left.and.right")),
                 SidebarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"))]

let Albums = GalleryInteractor.listAlbums().map { album in
    SidebarItem(title: album.name, image: UIImage(contentsOfFile: IndexInteractor.documentDirectory.appendingPathComponent(album.thumbnail).relativePath)?.resized(to: CGSize(width: 30, height: 30)))
}

let SmartAlbums = [SidebarItem(title: "Smart Albums", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2015", image: UIImage(systemName: "folder.badge.gearshape")),
                     SidebarItem(title: "Replay 2016", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2017", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2018", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2019", image: UIImage(systemName: "music.note.list")),]

class SidebarViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>! = nil
    private var collectionView: UICollectionView! = nil
    private var AllPhotosScreen: AlbumScreen = AlbumScreen()
    private var secondaryViewControllers: [UIViewController] = []
    private var screens: [IndexPath: UIViewController] = [:]
    private var previouslySelectedIndex = IndexPath(row: 0, section: 0)
    let disposeBag = DisposeBag()
    let imagePicker: UIImagePickerController = {
        let view = UIImagePickerController()
        view.allowsEditing = true
        return view
    }()
    let router = MainRouter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        let navigation = UINavigationController(rootViewController: AllPhotosScreen)
        self.screens.updateValue(navigation, forKey: IndexPath(row: 0, section: 0))
        secondaryViewControllers.append(navigation)

        let addAlbumButton = UIButton(type: .system)
        addAlbumButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addAlbumButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        addAlbumButton.rx.tap.subscribe(onNext: { [weak self] in
            let alertController = UIAlertController(title: "Enter Album name", message: nil, preferredStyle: .alert)

            alertController.addTextField { textField in
                textField.placeholder = "Album name"
            }

            let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak alertController] _ in
                guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
                if let albumName = alertController.textFields?.first?.text {
                    try! GalleryInteractor.createAlbum(name: albumName)
                }
            }
            alertController.addAction(confirmAction)

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            self?.present(alertController, animated: true, completion: nil)
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        
        navigationItem.title = "Hey"
        let selectGalleryButton: UIButton = { let view = UIButton()
//            view.backgroundColor = .green
            view.setTitle("Hey", for: .normal)
            view.setTitleColor(.black, for: .normal)
            view.frame = .zero
            view.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
            return view
        }()
        selectGalleryButton.rx.tap.subscribe(onNext: { [weak self] in
            let newController = UIViewController()
            newController.view.backgroundColor = .systemBackground
            self?.present(newController, animated: true, completion: nil)
        }).disposed(by: disposeBag)
        navigationItem.titleView = selectGalleryButton

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addAlbumButton)
        navigationController?.navigationBar.prefersLargeTitles = false

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: self.createLayout())
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false // This line fixes issue with incorrect highlighting
        view.addSubview(collectionView)
        ConfigureDataSource()
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        splitViewController?.setViewController(screens[IndexPath(row: 0, section: 0)], for: .secondary)
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
        
        let sections: [SidebarSection] = [.tabs, .albums, .playlists]
        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        for section in sections {
            switch section {
            case .tabs:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                sectionSnapshot.append(tabsItems)
                dataSource.apply(sectionSnapshot, to: section)
            case .albums:
                let headerItem = SidebarItem(title: section.rawValue, image: nil)
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                sectionSnapshot.append([headerItem])
                sectionSnapshot.append(Albums, to: headerItem)
                sectionSnapshot.expand([headerItem])
                dataSource.apply(sectionSnapshot, to: section)
            case .playlists:
                let headerItem = SidebarItem(title: section.rawValue, image: nil)
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                sectionSnapshot.append([headerItem])
                sectionSnapshot.append(SmartAlbums, to: headerItem)
                sectionSnapshot.expand([headerItem])
                dataSource.apply(sectionSnapshot, to: section)
            }
        }
    }

    func showDocumentPicker() {
        let allowedTypes: [UTType] = [UTType.image]

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        self.present(documentPicker, animated: true)
    }

    func showImagePicker() {
        self.present(self.imagePicker, animated: true)
    }

    func selectPreviousItem() {
        print(previouslySelectedIndex.row)
        self.collectionView.selectItem(at: previouslySelectedIndex, animated: false, scrollPosition: .top)
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row != 1 {
            self.previouslySelectedIndex = indexPath
        }
        guard indexPath.section == 0 else { return }
                
        if indexPath.row == 1 && indexPath.section == 0 {
            let alert = UIAlertController(title: "Select source", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("SELECTFROMFILES", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showDocumentPicker()
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Select from Gallery", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showImagePicker()
            })

            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = collectionView.cellForItem(at: IndexPath(row: 1, section: 0))
                presenter.sourceRect = collectionView.cellForItem(at: IndexPath(row: 1, section: 0))!.bounds
                presenter.delegate = self
            }

            self.present(alert, animated: true, completion: nil)
        } else {
            splitViewController?.setViewController(screens[indexPath], for: .secondary)
        }
    }
}

extension SidebarViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                
        for url in urls {
            do {
                try FileManager().moveItem(at: url, to: documentDirectory.first!.appendingPathComponent(url.lastPathComponent))
                print("Copied to \(url)")
                print("Document directory \(documentDirectory.first!)")
                AllPhotosScreen.importPhoto(filename: url.lastPathComponent, to: "Test")
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        selectPreviousItem()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        selectPreviousItem()
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("CreateSubAlbum", comment: ""),
                     image: UIImage(systemName: "plus.square")) { action in
                //                self.performInspect(indexPath)
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
                //                self.performDelete(indexPath)
            }
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }
}

extension SidebarViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        selectPreviousItem()
    }
}
