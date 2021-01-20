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
    let cellName = "GalleryCell"
    public var listedImages = GalleryManager.listImages()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.size.width / 3.3, height: view.frame.size.height / 3.3)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let gestureRecongizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        collectionView.addGestureRecognizer(gestureRecongizer)
        
//        collectionView.backgroundColor = .white
        collectionView.register(GalleryImageCell.self, forCellWithReuseIdentifier: self.cellName)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        for file in GalleryManager.listImages() {
            print("File at: \(file.absoluteURL)")
        }
    }
    
    public func reloadData() {
        self.listedImages = GalleryManager.listImages()
        collectionView.reloadData()
    }
    
    @objc func longPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let targetInexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            
            collectionView.beginInteractiveMovementForItem(at: targetInexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        case .cancelled:
            collectionView.cancelInteractiveMovement()
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
        return
    }
    
    var collectionView: UICollectionView! = nil
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellName, for: indexPath) as! GalleryImageCell
        cell.image.image = UIImage(contentsOfFile: listedImages[indexPath.row].relativePath)
        cell.index = indexPath.row
        cell.delegate = self
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: (collectionView.bounds.size.width/4), height: (view.frame.size.width/4))
//    }
//
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

class GalleryImageCell: UICollectionViewCell {
    weak var textLabel: UILabel!
    weak var image: UIImageView!
    var delegate: AllPhotos!
    var index: Int!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let label = UILabel()
        let imageView = UIImageView()
        
        let button = CheckBox(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.backgroundColor = .red
        button.setTitle("Not checked", for: .normal)
        button.isHidden = true

        label.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(label)
        contentView.addSubview(imageView)
        contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        textLabel = label
        image = imageView
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(galleryImageTapped(_:)))
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(tapRecognizer)
        
        imageView.contentMode = .scaleAspectFit
        textLabel.textAlignment = .center
        
//        image.addBlurEffect()
        image.backgroundColor = .none
        self.backgroundColor = .none
    }
    
    @objc func galleryImageTapped(_ sender: UITapGestureRecognizer) {
        print("Image tapped \(Date())")
        
        let PhotoDetailScreen = PhotoDetailViewController(nibName: "PhotoDetailViewController", bundle: nil)
        PhotoDetailScreen.modalPresentationStyle = .fullScreen
        PhotoDetailScreen.delegate = self.delegate
        PhotoDetailScreen.selectedIndex = self.index
        delegate.present(PhotoDetailScreen, animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
