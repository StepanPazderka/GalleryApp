//
//  PhotoDetailViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 19.12.2020.
//

import UIKit

class PhotoDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var imageSource: AllPhotos!
    var selectedIndex: Int!
    var initialScrollDone: Bool = false
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let deleteImageButton = UIButton(type: .system)
        deleteImageButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteImageButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: deleteImageButton)
        self.collectionView?.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)

        collectionView.delegate = self
        collectionView.dataSource = self

        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("CANCEL", comment: "Cancel"),
            action: #selector(didInvokeCancel),
            input: UIKeyCommand.inputEscape
        ))
        
        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("LEFT", comment: "Previous item"),
            action: #selector(selectPreviousItem),
            input: UIKeyCommand.inputLeftArrow
        ))
        
        addKeyCommand(UIKeyCommand(
            title: NSLocalizedString("RIGHT", comment: "Next item"),
            action: #selector(selectNextItem),
            input: UIKeyCommand.inputRightArrow
        ))

        navigationItem.title = imageSource.listedImages[selectedIndex]
        
        let nib = UINib(nibName: "InteractiveImageViewCell", bundle: Bundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "ImageViewCell")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let observedObject = object as? UICollectionView, observedObject == collectionView {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
        self.collectionView?.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.collectionView?.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        
        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
         // Use interfaceOrientation
        }
        
        flowLayout.invalidateLayout()

        let indexPath = IndexPath(item: selectedIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    @IBAction @objc func didInvokeCancel() {
        imageSource.navigationController?.popViewController(animated: true)
    }

    @IBAction func didTapDelete(_ sender: Any) {
        
    }

    @IBAction func selectPreviousItem(_ sender: Any) {
        if selectedIndex > 0 {
            selectedIndex = selectedIndex-1
        }
        
        let indexPath = IndexPath(item: selectedIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
    
    @IBAction func selectNextItem(_ sender: Any) {
        if selectedIndex < imageSource.listedImages.count-1 {
            selectedIndex = selectedIndex+1
        }
        
        let indexPath = IndexPath(item: selectedIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of images fetched to collectionView \(imageSource.listedImages.count)")
        return imageSource.listedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath as IndexPath) as! InteractiveImageViewCell
        if let image = URL(string: imageSource.listedImages[indexPath.row]) {
            cell.imageView.image = UIImage(contentsOfFile: GalleryManager.documentDirectory.appendingPathComponent(image.absoluteString).relativePath)
        }

//        cell.imageView.image = UIImage(contentsOfFile: GalleryManager.documentDirectory.appendingPathComponent(imageSource.listedImages[indexPath.row].lastPathComponent).absoluteString)
        cell.scrollView.delegate = cell
        return cell
    }
}
