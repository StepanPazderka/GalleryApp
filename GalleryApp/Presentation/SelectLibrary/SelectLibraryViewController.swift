//
//  SelectLibraryViewController.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 22.04.2023.
//

import Foundation
import UIKit
import RxDataSources
import RxSwift

class SelectLibraryViewController: UIViewController {
    
    // MARK: - Views
    let screenView = SelectLibraryView()
    let viewModel: SelectLibraryViewModel
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, String>>?
    
    init(viewModel: SelectLibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.configureDataSource()
        self.screenView.galleriesCollectionView.register(SelectLibraryCell.self, forCellWithReuseIdentifier: SelectLibraryCell.identifier)
        self.viewModel.libraries.bind(to: screenView.galleriesCollectionView.rx.items(dataSource: dataSource!)).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.setupViews()
        self.layoutViews()
        self.bindInteractions()
        
        self.highlightSelectedLibraryInList()
    }
    
    func bindInteractions() {
        self.screenView.galleriesCollectionView.rx.itemSelected.subscribe(onNext: { [weak self] index in
            guard let self else { return }
            if let libraryName = self.dataSource?.sectionModels.first?.items[index.item] {
                self.viewModel.switchTo(library: libraryName)
                self.dismiss(animated: true)
            }
        }).disposed(by: disposeBag)
        
        self.screenView.rightBarButton.rx.tap.subscribe(onNext: {
            self.showCreateLibraryDialog(callback: { name in
                do {
                    try self.viewModel.createNewLibrary(withName: name, callback: {
                        self.viewModel.updateLibraries()
                    })
                } catch {
                    
                }
            })
        }).disposed(by: disposeBag)
        
        self.screenView.closeButton.rx.tap.subscribe(onNext: {
            self.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    func highlightSelectedLibraryInList() {
        
        let loadedGalleryName = self.viewModel.getSelectedLibraryString()
        var index: Int?
        let selectedItem = self.dataSource?.sectionModels.first(where: { section in
            index = section.items.firstIndex(where: { item in
                item == loadedGalleryName
            })
            return true
        })
        
        if let index {
            self.screenView.galleriesCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .centeredVertically)
        }
    }
    
    func configureDataSource() {
        self.dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, String>>(configureCell: { dataSource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectLibraryCell.identifier, for: indexPath) as! SelectLibraryCell
            cell.text.text = item
            return cell})
    }
    
    // MARK: - Create Album Popover
    @objc func showCreateLibraryDialog(withPrepulatedName: String? = nil, callback: ((String) -> Void)? = nil) {
        var returnString: String?
        let createAlbumAlert = UIAlertController(title: NSLocalizedString("kEnterLibraryName", comment: ""), message: nil, preferredStyle: .alert)

        createAlbumAlert.addTextField { textField in
            textField.placeholder = NSLocalizedString("kLibraryName", comment: "Library name")
            
            if let withPrepulatedName {
                textField.text = withPrepulatedName
            }
        }
                
        let confirmAction = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .default) { [weak createAlbumAlert] _ in
            guard let alertController = createAlbumAlert, let textField = alertController.textFields?.first, let text = textField.text else { return }
            
            if text.isEmpty {
                let okAction = UIAlertAction(title: NSLocalizedString("kOK", comment: ""), style: .destructive)
                
                let noAlbumAlert = UIAlertController(title: NSLocalizedString("kAlbumNameCantBeEmpty", comment: ""), message: nil, preferredStyle: .alert)
                noAlbumAlert.addAction(okAction)
                self.present(noAlbumAlert, animated: true)
                returnString = nil
                return
            }
            
            if let albumName = textField.text, !text.isEmpty {
                returnString = albumName
            }
            
            if let callback, let returnString {
                callback(returnString)
            }
        }
        createAlbumAlert.addAction(confirmAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("kCANCEL", comment: "Cancel"), style: .cancel, handler: nil)
        createAlbumAlert.addAction(cancelAction)

        self.present(createAlbumAlert, animated: true, completion: nil)
    }
    
    func setupViews() {
        self.view = screenView
    }
    
    func layoutViews() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: screenView.closeButton)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: screenView.rightBarButton)
        self.navigationItem.title = NSLocalizedString("kSELECTLIBRARY", comment: "Select library to load")
    }
}
