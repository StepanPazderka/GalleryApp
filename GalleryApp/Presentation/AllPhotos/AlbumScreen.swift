//
//  EmptyViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit
import RxSwift
import RxCocoa

enum GallerySection: String {
    case main
}

struct GalleryItem: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()
}

let testGalleryImages = [GalleryItem(title: "name1", image: UIImage(named: "sampleImage"))]

class AlbumScreen: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ListsImages {
    var collectionView: UICollectionView?
    let cellName = "GalleryCell"
    let disposeBag = DisposeBag()
    public var listedImages = IndexInteractor.loadIndex(folder: IndexInteractor.documentDirectory)?.images
    var editingOn = false
    var editingRx = BehaviorRelay<Bool>(value: false)
    let doneButton: UIButton = { let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        return button
    }()
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
//        button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        button.sizeToFit()
        return button
    }()
    let addImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add", for: .normal)
//        button.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        button.sizeToFit()
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if FileManager.default.fileExists(atPath: IndexInteractor.documentDirectory.appendingPathComponent("index.json").path) == true {
            print("Index exists")
        } else {
            IndexInteractor.rebuildIndex(folder: IndexInteractor.documentDirectory)
        }
        self.listedImages = IndexInteractor.loadIndex(folder: IndexInteractor.documentDirectory)?.images

        editButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.editingRx.accept(true)

        }).disposed(by: disposeBag)

        doneButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.editingRx.accept(false)
        }).disposed(by: disposeBag)

        self.navigationItem.title = "Gallery"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addImageButton)

        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.itemSize = CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
        collectionLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView?.translatesAutoresizingMaskIntoConstraints = false

        editingRx.bind(onNext: { [weak self] value in
            self?.setEditing(value, animated: true)
            if let doneButton = self?.doneButton, let editButton = self?.editButton {
                if value {
                    self?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: doneButton)
                } else {
                    self?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: editButton)
                }
            }
        }).disposed(by: disposeBag)
        if let collectionView = self.collectionView {
            view.addSubview(collectionView)

            collectionView.delegate = self
            collectionView.dataSource = self

            NSLayoutConstraint.activate([
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        let gestureRecongizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        collectionView?.addGestureRecognizer(gestureRecongizer)
        collectionView?.register(AlbumImageCell.self, forCellWithReuseIdentifier: self.cellName)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    func importPhoto(filename: String, to album: String) {
        self.listedImages?.append(filename)
        IndexInteractor.rebuildIndex(folder: IndexInteractor.documentDirectory)
        collectionView?.reloadData()
    }
    
    public func reloadData() {
        self.listedImages = IndexInteractor.listImages()
        collectionView?.reloadData()
    }
    
    @objc func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let targetIndexPath = collectionView?.indexPathForItem(at: gesture.location(in: collectionView)) else {
            return
        }

        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1, animations: {
                (self.collectionView!.cellForItem(at: targetIndexPath) as! AlbumImageCell).transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            })
            collectionView?.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView?.endInteractiveMovement()
        case .cancelled:
            collectionView?.cancelInteractiveMovement()
        default:
            print("Default")
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.collectionView?.allowsMultipleSelection = editing
        self.collectionView?.indexPathsForVisibleItems.forEach { (indexPath) in
            let cell = collectionView?.cellForItem(at: indexPath) as! AlbumImageCell
            cell.isEditing = editing
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var temp = listedImages?.remove(at: sourceIndexPath.item)
        if let temp = temp {
            listedImages?.insert(temp, at: destinationIndexPath.item)
        }

        let newGalleryIndex = AlbumIndex(name: IndexInteractor.documentDirectory.lastPathComponent, images: listedImages ?? [String](), thumbnail: listedImages?.first ?? "")
        IndexInteractor.updateIndex(folder: IndexInteractor.documentDirectory, index: newGalleryIndex)
        collectionView.reloadData()
        return
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            let inspectAction =
            UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                     image: UIImage(systemName: "arrow.up.square")) { action in
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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listedImages?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellName, for: indexPath) as! AlbumImageCell
        if let selectedImageURL = listedImages?[indexPath.row] {
            if let image = URL(string: selectedImageURL) {
                let fullImageURL = IndexInteractor.documentDirectory.appendingPathComponent(image.absoluteString).relativePath
                cell.albumImage.image = UIImage(contentsOfFile: fullImageURL)
            }
        }

        cell.index = indexPath.row
        cell.delegate = self
        editingRx.subscribe(onNext: { value in
            cell.isEditingRX.accept(value)
        }).dispose()
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView?.frame = view.bounds
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
}


