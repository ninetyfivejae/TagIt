//
//  PhotoViewController.swift
//  TagIt
//
//  Created by 신재혁 on 18/02/2019.
//  Copyright © 2019 ninetyfivejae. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    let imageCachingManager = PHCachingImageManager()
    var thumbnailSize: CGSize!
    var previousPreheatRect = CGRect.zero
    var requestOptions = PHImageRequestOptions()
    var cellSize: CGSize!
    
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
    }
    
    func prepareUsingPhotos() {
        self.resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        if self.fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
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
            guard let destination = segue.destination as? PageViewController else {
                fatalError("unexpected view controller for segue")
            }
            
            let indexPath = self.collectionView.indexPath(for: sender as! UICollectionViewCell)!
            destination.fetchResult = self.fetchResult
            destination.selectedPhotoIndex = indexPath
        }
    }
}

// MARK: UICollectionView

extension PhotoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoItemCell.self), for: indexPath) as? PhotoItemCell else {
            fatalError("unexpected cell in collection view")
        }
        
        let asset = fetchResult.object(at: indexPath.item)
        cell.representedAssetIdentifier = asset.localIdentifier
        
        self.imageCachingManager.requestImage(for: asset, targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, info in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                //configure
                cell.thumbnailImage = image
                //cell.taggedLabel.isHidden = false
            }
        })
        
        
        //보류
        //select 해당 사진 파일해서, 데이터 있고 태그가 달려있으면 collectionView에 표시해주기 / 이 부분 때문에 느려져서 prefetching에서 데이터를 가져와야할듯함
//        self.imageCachingManager.requestImageData(
//            for: asset, options: self.requestOptions, resultHandler: { (imagedata, dataUTI, orientation, info) in
//                if let info = info {
//                    if info.keys.contains(NSString(string: "PHImageFileURLKey")) {
//                        if let path = info[NSString(string: "PHImageFileURLKey")] as? NSURL {
//                            RealmManager.sharedInstance.testRealmMananger()
//                            if path.lastPathComponent == "IMG_1234" {
//                                print("JACKPOT!!! JACKPOT!!! JACKPOT!!!")
//                            }
//                        }
//                    }
//                }
//        })
        
        
        
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
        imageCachingManager.stopCachingImagesForAllAssets()
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
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        imageCachingManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageCachingManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
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
        
        guard let changes = changeInstance.changeDetails(for: fetchResult) else { return }
        
        DispatchQueue.main.sync {
            fetchResult = changes.fetchResultAfterChanges
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