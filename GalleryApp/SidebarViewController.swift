//
//  SidebarViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit
import UniformTypeIdentifiers

enum SidebarSection: String {
    case tabs
    case library = "Library"
    case playlists = "Playlists"
}

struct SidebarItem: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()
}

let tabsItems = [SidebarItem(title: "All Photos", image: UIImage(systemName: "photo.on.rectangle.angled")),
                 SidebarItem(title: "Import photo", image: UIImage(systemName: "square.grid.2x2")),
                 SidebarItem(title: "Radio", image: UIImage(systemName: "dot.radiowaves.left.and.right")),
                 SidebarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"))]

let libraryItems = [SidebarItem(title: "Recently Added", image: UIImage(systemName: "clock")),
                    SidebarItem(title: "Artists", image: UIImage(systemName: "music.mic")),
                    SidebarItem(title: "Albums", image: UIImage(systemName: "rectangle.stack")),
                    SidebarItem(title: "Songs", image: UIImage(systemName: "music.note")),
                    SidebarItem(title: "Music Videos", image: UIImage(systemName: "tv.music.note")),
                    SidebarItem(title: "TV & Movies", image: UIImage(systemName: "tv"))]

let playlistItems = [SidebarItem(title: "All Playlists", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2015", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2016", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2017", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2018", image: UIImage(systemName: "music.note.list")),
                     SidebarItem(title: "Replay 2019", image: UIImage(systemName: "music.note.list")),]

class SidebarViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>! = nil
    private var collectionView: UICollectionView! = nil
    private var AllPhotosScreen: AllPhotos = AllPhotos()
    private var secondaryViewControllers: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigation = UINavigationController(rootViewController: AllPhotosScreen)

        navigation.popToRootViewController(animated: true)
        secondaryViewControllers.append(navigation)
        
        navigationItem.title = nil
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
            content.image = item.image
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
        
        let sections: [SidebarSection] = [.tabs, .library, .playlists]
        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItem>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)

        for section in sections {
            switch section {
            case .tabs:
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                sectionSnapshot.append(tabsItems)
                dataSource.apply(sectionSnapshot, to: section)
            case .library:
                let headerItem = SidebarItem(title: section.rawValue, image: nil)
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                sectionSnapshot.append([headerItem])
                sectionSnapshot.append(libraryItems, to: headerItem)
                sectionSnapshot.expand([headerItem])
                dataSource.apply(sectionSnapshot, to: section)
            case .playlists:
                let headerItem = SidebarItem(title: section.rawValue, image: nil)
                var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
                sectionSnapshot.append([headerItem])
                sectionSnapshot.append(playlistItems, to: headerItem)
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
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        self.present(picker, animated: true)
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
                
        if indexPath.row == 1 {
            let alert = UIAlertController(title: "My Alert", message: "This is an alert.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Select from Files", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showDocumentPicker()
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Select from Gallery", comment: "Default action"), style: .default) { [weak self] _ in
                self?.showImagePicker()
            })
            self.present(alert, animated: true, completion: nil)
        } else {
            splitViewController?.setViewController(secondaryViewControllers[indexPath.row], for: .secondary)
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
                AllPhotosScreen.reloadData()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
