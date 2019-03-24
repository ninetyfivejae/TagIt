//
//  SearchedPhotoItemCell.swift
//  TagIt
//
//  Created by 신재혁 on 24/03/2019.
//  Copyright © 2019 ninetyfivejae. All rights reserved.
//

import UIKit

class SearchedPhotoItemCell: UICollectionViewCell {
    
	@IBOutlet weak var imageView: UIImageView!
	
	var representedAssetIdentifier: String!
	
	var thumbnailImage: UIImage! {
		didSet {
			imageView.image = thumbnailImage
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		imageView.image = nil
	}
}
