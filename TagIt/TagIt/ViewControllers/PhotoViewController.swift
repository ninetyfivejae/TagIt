import UIKit
import Photos
import PhotosUI

class PhotoViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
		@IBOutlet weak var selectButton: UIBarButtonItem!
	
    var thumbnailSize: CGSize!
    var previousPreheatRect = CGRect.zero
    var requestOptions = PHImageRequestOptions()
    var cellSize: CGSize!
	
		var isSelectMode: Bool = false
		var selectedPhotosList: [UIImage?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        initialSettings()
        prepareUsingPhotos()
    }
    
    func initialSettings() {
        self.cellSize = self.collectionViewFlowLayout.itemSize
        self.thumbnailSize = CGSize(width: cellSize.width, height: cellSize.height)
				clearStatusBar()
				clearNavigationBar()
				clearToolbar()
				toolBarVisibleSettings(isHidden: true)
    }
    
    func prepareUsingPhotos() {
        self.resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateCachedAssets()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PageViewControllerSegue" {
            guard let pageViewController = segue.destination as? PageViewController else {
                fatalError("unexpected view controller for segue")
            }
					
						PhotographManager.sharedInstance.isSearchedPhotoType = false
            let indexPath = self.collectionView.indexPath(for: sender as! UICollectionViewCell)!
            pageViewController.selectedPhotoIndex = indexPath
        }
    }
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if isSelectMode {
			return false
		} else {
			return true
		}
	}
	
	func toolBarVisibleSettings(isHidden: Bool) {
		navigationController?.setToolbarHidden(isHidden, animated: true)
		self.selectedPhotosList.removeAll()
		if isHidden {
			self.navigationController?.toolbar.isTranslucent = true
			self.selectButton.title = "•••"
			self.collectionView.reloadData()
		} else {
			self.navigationController?.toolbar.isTranslucent = false
			self.selectButton.title = "취소"
		}
	}
	
	@IBAction func selectButtonTapped(_ sender: Any) {
		isSelectMode.toggle()
		toolBarVisibleSettings(isHidden: !isSelectMode)
	}
	
	@IBAction func shareButtonTapped(_ sender: Any) {
		let activityViewController = UIActivityViewController(activityItems: self.selectedPhotosList, applicationActivities: nil)
		activityViewController.popoverPresentationController?.sourceView = self.view
		self.present(activityViewController, animated: true, completion: nil)
	}
	
}

// MARK: UICollectionView

extension PhotoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PhotographManager.sharedInstance.fetchResult.count
    }
	
		func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
			
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoItemCell.self), for: indexPath) as? PhotoItemCell else {
				fatalError("unexpected cell in collection view")
			}
			
			if isSelectMode {
				self.collectionView.allowsMultipleSelection = isSelectMode
				self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
				
				PhotographManager.sharedInstance.requestOriginalImage(options: requestOptions, selectedIndexPath: indexPath.item) { image in
					self.selectedPhotosList.append(image)
				}
				cell.isSelected = true
			} else {
				cell.isSelected = false
				self.collectionView.deselectItem(at: indexPath, animated: true)
			}
			
		}
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
			
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoItemCell.self), for: indexPath) as? PhotoItemCell else {
					fatalError("unexpected cell in collection view")
			}
			
			PhotographManager.sharedInstance.requestThumnailImage(targetSize: self.thumbnailSize, options: nil, selectedIndexPath: indexPath.item, cell: cell) { image in
				cell.thumbnailImage = image
			}
			return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = self.collectionView.frame.width
        
        if DeviceInfo.Orientation.isPortrait {
            return CGSize(width: width/4 - 1, height: width/4 - 1)
        } else {
            return CGSize(width: width/6 - 1, height: width/6 - 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
	
}

// MARK: UIScrollView

extension PhotoViewController: UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
        
        if getScrollViewSpeed(scrollView) > 10.0 {
            self.thumbnailSize = CGSize(width: cellSize.width * 0.5, height: cellSize.height * 0.5)
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        reloadPhotosWithOriginalSize()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        perform(#selector(self.actionOnFinishedScrolling), with: nil, afterDelay: Double(velocity.x))
    }
    
    func getScrollViewSpeed(_ scrollView: UIScrollView) -> Float {
        let lastOffset: CGPoint? = CGPoint()
        let lastOffsetCapture: TimeInterval? = 0
        let currentOffset = scrollView.contentOffset
        let currentTime = NSDate().timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastOffsetCapture!
        let captureInterval = 0.1
        
        if timeDiff > captureInterval {
            let distance = currentOffset.y - lastOffset!.y     // calc distance
            let scrollSpeedNotAbs = (distance * 10) / 1000     // pixels per ms*10
            let scrollSpeed = fabsf(Float(scrollSpeedNotAbs))  // absolute value
            
            return scrollSpeed
        } else {
            return 0
        }
    }
    
    @objc func actionOnFinishedScrolling() {
        reloadPhotosWithOriginalSize()
    }
    
    func reloadPhotosWithOriginalSize() {
        thumbnailSize = CGSize(width: cellSize.width, height: cellSize.height)
        collectionView.reloadData()
    }
	
}

// MARK: Asset Caching

extension PhotoViewController {
    
    fileprivate func resetCachedAssets() {
        PhotographManager.sharedInstance.imageCachingManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else { return }
        
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in PhotographManager.sharedInstance.fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in PhotographManager.sharedInstance.fetchResult.object(at: indexPath.item) }
        
        PhotographManager.sharedInstance.imageCachingManager.startCachingImages(for: addedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        PhotographManager.sharedInstance.imageCachingManager.stopCachingImages(for: removedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY, width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY, width: new.width, height: old.minY - new.minY)]
            }
            
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY, width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY, width: new.width, height: new.minY - old.minY)]
            }
            
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
	
}

// MARK: PHPhotoLibraryChangeObserver

extension PhotoViewController: PHPhotoLibraryChangeObserver {
	
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: PhotographManager.sharedInstance.fetchResult) else { return }
        
        DispatchQueue.main.sync {
            PhotographManager.sharedInstance.fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0), to: IndexPath(item: toIndex, section: 0))
                    }
                })
            } else {
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
	
}
