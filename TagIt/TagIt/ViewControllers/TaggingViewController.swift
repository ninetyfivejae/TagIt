//
//  TaggingViewController.swift
//  TagIt
//
//  Created by 신재혁 on 20/02/2019.
//  Copyright © 2019 ninetyfivejae. All rights reserved.
//

import UIKit
import Photos

let BGColor = UIColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

class ModalNavigationController: UINavigationController {
    
    weak var semiModalPresentationController: SemiModalPresentationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        semiModalPresentationController = presentationController as? SemiModalPresentationController
        
        navigationBar.backgroundColor = BGColor
        view.backgroundColor = BGColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}

class TaggingViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightContraint: NSLayoutConstraint!
    
    private var isFirst: Bool = true
    var selectedIndex: Int?
    
    var selectedColor: UIColor = UIColor(hexFromString: "555555")
    
    var selectedPhoto: Photograph?
    var fetchResult: PHFetchResult<PHAsset>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.textField.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        initialSettings()
        keyboardSettings()
    }
    
    func initialSettings() {
        self.tableViewHeightContraint.constant = self.view.height / 2
        self.view.backgroundColor = BGColor
        self.tableView.backgroundColor = BGColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        navigationController?.view.layoutIfNeeded()
        
        if isFirst {
            fitting(animated: true)
            isFirst = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isFirst {
            fitting(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func fitting(animated: Bool) {
        if let navi = navigationController as? ModalNavigationController {
            var height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            height += navi.navigationBar.frame.height
            navi.semiModalPresentationController?.setModalViewHeight(height, animated: animated)
        }
    }
}

// MARK: UITableView

extension TaggingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section:Int) -> String? {
        if section == 0 {
            return "설정"
        } else {
            return "추가된 태그"
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            if let photo = self.selectedPhoto {
                return photo.tagList.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = UITableViewCell()
            cell.backgroundColor = BGColor
            cell.textLabel?.textColor = .darkGray
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17.0)
            cell.textLabel?.text = "🍑 색깔 추가"
            return cell
            
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaggingViewCell", for: indexPath) as? TaggingViewCell else {
                return UITableViewCell()
            }
            
            if let photo = selectedPhoto {
                cell.tagLabel.text = photo.listToArray(objectList: photo.tagList)[indexPath.row]
                cell.colorTagView.backgroundColor = UIColor(hexFromString: photo.colorId)
            }
            cell.selectionStyle = .none
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "AddColorSegue", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddColorSegue" {
            guard let destination = segue.destination as? ColorPickerViewController else {
                fatalError("unexpected view controller for segue")
            }
            
            let indexPath = self.tableView.indexPathForSelectedRow
            destination.updateColorDelegate = self
            destination.selectedTagIndex = indexPath
            
        } else if segue.identifier == "UnwindTaggingSegue" {
            guard let destination = segue.destination as? ZoomedPhotoViewController else {
                fatalError("unexpected view controller for segue")
            }
//            let photograph: Photograph = Photograph(name: "IMG_3945.JPG", localIdentifier: "31F10CB8-530F-4684-9673-96CB2338AA70/L0/001", colorId: "FDA293", tagArray: ["여행", "음식"])
//            RealmManager.sharedInstance.saveObjects(object: photograph)
            
            print(RealmManager.sharedInstance.getObjects(type: Photograph.self))
            
//            var tagString: String = ""
//            for tag in tagList {
//                tagString.append("● " + tag + "\n")
//            }
//
//            destination.textView.text = tagString
            destination.textView.resolveHashTags()
            destination.textView.font = UIFont.systemFont(ofSize: 17.0)
            destination.textView.textColor = .darkGray
        }
    }
    
    func imageTagSettings() {
        let asset: PHAsset = self.fetchResult.object(at: self.selectedIndex!)
        
        PHImageManager.default().requestImageData(for: asset, options: PHImageRequestOptions(), resultHandler: { (imagedata, dataUTI, orientation, info) in
            if let info = info {
                if info.keys.contains(NSString(string: "PHImageFileURLKey")) {
                    if let path = info[NSString(string: "PHImageFileURLKey")] as? NSURL {
                        if let result = RealmManager.sharedInstance.getObjects(type: Photograph.self)?.filter("name = %@", path.lastPathComponent).first {
                            self.selectedPhoto = result
                            
                        } else {
                            self.selectedPhoto = Photograph()
                            
                        }
                    }
                }
            }
        })
    }
}

extension TaggingViewController: UpdateColorDelegate {
    func updateColor(selectedColor: UIColor) {
        self.selectedColor = selectedColor
        self.tableView.reloadData()
        
        //color add
        
    }
}

// MARK: - keyboard handle

extension TaggingViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        tagList.append(String(textField.text!))
        self.tableView.reloadData()
        self.textField.text = ""
        self.textField.resignFirstResponder()
        return true
    }
    
    func keyboardSettings() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTextView(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTextView(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.textField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    @objc func updateTextView(notification: Notification) {
        if let userInfo = notification.userInfo {
            let keyboardFrameScreenCoordinates = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardFrame = self.view.convert(keyboardFrameScreenCoordinates, to: view.window)
            
            if notification.name == UIResponder.keyboardWillHideNotification {
                view.frame.origin.y = 0
            } else {
                view.frame.origin.y = -keyboardFrame.height
            }
        }
        fitting(animated: true)
    }
}