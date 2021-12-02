//
//  EmptyViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 13.12.2020.
//

import UIKit

enum GallerySection: String {
    case main
}

struct GalleryItem: Hashable {
    let title: String?
    let image: UIImage?
    private let identifier = UUID()
}

let testGalleryImages = [GalleryItem(title: "name1", image: UIImage(named: "sampleImage"))]

class AllPhotos: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ListsImages {
    var collectionView: UICollectionView?
    let cellName = "GalleryCell"
    public var listedImages: [String] = GalleryManager.loadIndex(folder: GalleryManager.documentDirectory).images
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if FileManager.default.fileExists(atPath: GalleryManager.documentDirectory.appendingPathComponent("index.json").path) == true {
            print("Index exists")
        } else {
            GalleryManager.rebuildIndex(folder: GalleryManager.documentDirectory)
        }
        self.listedImages = GalleryManager.loadIndex(folder: GalleryManager.documentDirectory).images
        let editButton = UIButton(type: .system)
        editButton.titleLabel?.text = "Edit"
        editButton.setTitle("Edit", for: .normal)
        editButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        self.navigationItem.title = "Gallery"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: editButton)

        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.itemSize = CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
        collectionLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView?.translatesAutoresizingMaskIntoConstraints = false

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

    func importPhoto(filename: String) {
        self.listedImages.append(filename)
        GalleryManager.rebuildIndex(folder: GalleryManager.documentDirectory)
        collectionView?.reloadData()
    }
    
    public func reloadData() {
        self.listedImages = GalleryManager.listImages()
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = listedImages.remove(at: sourceIndexPath.item)
        listedImages.insert(temp, at: destinationIndexPath.item)
        
        let newGalleryIndex = AlbumIndex(name: GalleryManager.documentDirectory.lastPathComponent, images: listedImages, thumbnail: listedImages.first ?? "")
        GalleryManager.updateIndex(folder: GalleryManager.documentDirectory, index: newGalleryIndex)
        collectionView.reloadData()
        return
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellName, for: indexPath) as! AlbumImageCell
        if let image = URL(string: listedImages[indexPath.row]) {
            let fullImageURL = GalleryManager.documentDirectory.appendingPathComponent(image.absoluteString).relativePath
            cell.albumImage.image = UIImage(contentsOfFile: fullImageURL)
        }
        cell.index = indexPath.row
        cell.delegate = self
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


