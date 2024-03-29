//
//  PhotoDetailViewControllerNew.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.01.2022.
//

import UIKit
import RxSwift
import RxDataSources
import SnapKit

struct ZoomScale {
    let x: CGFloat
    let y: CGFloat
}

class PhotoDetailViewController: UIViewController {
    
    // MARK: - Properties
    var singleTapGestureRecognizer = UITapGestureRecognizer()
    
    let screenView = PhotoDetailView()
    var viewModel: PhotoDetailViewModel
    
    var dataSource: RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, GalleryImage>>!
    var zoomScale: ZoomScale?
    let disposeBag = DisposeBag()
    var initialScrollDone = false
    
    // MARK: - Init
    internal init(viewModel: PhotoDetailViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        self.setupViews()
        self.configureDataSource()
        self.bindData()
        self.bindInteractions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.screenView.collectionViewLayout.itemSize = screenView.bounds.size
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.scrollTo(index: self.viewModel.index, animated: false)
        
    }
    
    // MARK: - Layout
    private func setupViews() {
        self.view = screenView
        self.view.backgroundColor = .systemBackground
        
        self.screenView.collectionView.register(PhotoDetailCollectionViewCell.self, forCellWithReuseIdentifier: PhotoDetailCollectionViewCell.identifier)
        self.screenView.collectionView.delegate = self
        
        self.screenView.addGestureRecognizer(screenView.swipeDownGestureRecognizer)
    }
    
    // MARK: - Binding Interactions
    private func bindInteractions() {
        self.screenView.closeButton.rx.tap.subscribe(onNext:  { [weak self] in
            self?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        self.screenView.swipeDownGestureRecognizer.rx.event.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            
            let translation = screenView.swipeDownGestureRecognizer.translation(in: view)
            
            switch self.screenView.swipeDownGestureRecognizer.state {
            case .changed:
                if translation.y > 0 {  // Only allow dragging downwards
                    view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                }
            case .ended:
                if translation.y > 100 {
                    dismiss(animated: true, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.screenView.transform = CGAffineTransform.identity
                    }
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Data Binding
    private func bindData() {
        Observable
            .from(optional: viewModel.images)
            .flatMap{
                Observable.just([AnimatableSectionModel(model: "Section", items: $0)])
            }
            .bind(to: self.screenView.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel.indexAsObservable.subscribe(onNext: { index in
            self.scrollTo(index: index, animated: false)
        }).disposed(by: disposeBag)
    }
    
    func configureDataSource() {
        dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, GalleryImage>>(
            configureCell: { [unowned self] (dataSource, collectionView, indexPath, item) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoDetailCollectionViewCell.identifier, for: indexPath) as! PhotoDetailCollectionViewCell
                var itemWithResolvedPath = item
                itemWithResolvedPath.fileName = self.viewModel.resolveThumbPathFor(image: itemWithResolvedPath.fileName)
                cell.configure(image: itemWithResolvedPath)
                return cell
            }
        )
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                self.dismiss(animated: true)
            }
            
            if key.charactersIgnoringModifiers == UIKeyCommand.inputLeftArrow {
                self.viewModel.showImage(.previous)
            } else if key.charactersIgnoringModifiers == UIKeyCommand.inputRightArrow {
                self.viewModel.showImage(.next)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.screenView.collectionViewLayout.invalidateLayout()
        
        coordinator.animate(alongsideTransition: { context in
            self.screenView.collectionViewLayout.itemSize = self.screenView.collectionView.frame.size
            let onePercentageOfX = self.screenView.collectionView.contentSize.width / 100
            let offsetOfX = self.screenView.collectionView.contentOffset.x / onePercentageOfX
            print(offsetOfX)
            
            let onePercentageOfY = self.screenView.collectionView.contentSize.height / 100
            let offsetOfY = self.screenView.collectionView.contentOffset.y / onePercentageOfY
            print(offsetOfY)
            
            self.zoomScale = ZoomScale(x: offsetOfX, y: offsetOfY)
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                self.screenView.collectionViewLayout.itemSize = self.screenView.collectionView.frame.size
                
                if let zoomScale = self.zoomScale {
                    let onePercentageOfX = self.screenView.collectionView.contentSize.width / 100
                    
                    let onePercentageOfY = self.screenView.collectionView.contentSize.height / 100
                    
                    let cgPoint = CGPoint(x: onePercentageOfX * zoomScale.x, y: onePercentageOfY * zoomScale.y)
                    self.screenView.collectionView.contentOffset = cgPoint
                }
                self.scrollTo(index: self.viewModel.index, animated: false)
            }
        })
    }
    
    func scrollTo(index: IndexPath, animated: Bool) {
        self.screenView.collectionView.isPagingEnabled = false
        self.screenView.collectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: animated)
        self.screenView.collectionView.isPagingEnabled = true
    }
}

extension PhotoDetailViewController: UICollectionViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let visibleCells = screenView.collectionView.visibleCells as! [PhotoDetailCollectionViewCell]
        //        for cell in visibleCells {
        //            if let indexPath = screenView.collectionView.indexPath(for: cell) {
        //                print(indexPath)
        //            }
        //        }
        //        let cell = visibleCells.first!
        //        print(screenView.collectionView.indexPath(for: cell))
        
        for cell in visibleCells {
            if let indexPath = screenView.collectionView.indexPath(for: cell) {
                if let cellFrame = screenView.collectionView.layoutAttributesForItem(at: indexPath)?.frame {
                    let cellVisibleRect = screenView.collectionView.convert(cellFrame, to: screenView.collectionView)
                    if !screenView.collectionView.bounds.intersects(cellVisibleRect) {
                        cell.imageView.zoomScale = 1.0
                    } else {
                        let indexPath = screenView.collectionView.indexPath(for: cell)
                        if viewModel.index != indexPath {
                            self.viewModel.index = indexPath!
                        }
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleCells = screenView.collectionView.visibleCells as! [PhotoDetailCollectionViewCell]
        
        for cell in visibleCells {
            if let indexPath = screenView.collectionView.indexPath(for: cell) {
                if let cellFrame = screenView.collectionView.layoutAttributesForItem(at: indexPath)?.frame {
                    let cellVisibleRect = screenView.collectionView.convert(cellFrame, to: screenView.collectionView)
                    if screenView.collectionView.bounds.intersects(cellVisibleRect) {
                        screenView.collectionView.bounds.intersects(cellVisibleRect)
                        let indexPath = self.screenView.collectionView.indexPath(for: cell)
                        
                        if self.viewModel.index != indexPath {
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                                self.viewModel.index = indexPath!
                            }
                        }
                    }
                }
            }
        }
    }
}
