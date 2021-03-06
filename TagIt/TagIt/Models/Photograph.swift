import UIKit
import RealmSwift
import Photos

final class Photograph: Object {
	
    @objc dynamic var name: String!
    @objc dynamic var localIdentifier: String!
    @objc dynamic var colorId: String!
    let tagList = List<String>()
    
    override static func primaryKey() -> String? {
        return "name"
    }
    
    convenience init(name : String, localIdentifier: String, colorId: String, tagArray: [String]) {
        self.init()
        self.name = name
        self.localIdentifier = localIdentifier
        self.colorId = colorId
    }
    
    func arrayToList(objectArray: [String]) -> List<String> {
        var objectList: List<String> = List<String>()
        
        for object in objectArray {
            objectList.append(object)
        }
        
        return objectList
    }
    
    func listToArray(objectList: List<String>) -> [String] {
        var objectArray: [String] = []
        
        for object in objectList {
            objectArray.append(object)
        }
        
        return objectArray
    }
	
		func deleteTag(tagIndexPath: IndexPath) {
				RealmManager.sharedInstance.deleteTagObject(object: self, tagIndexPath: tagIndexPath)
		}
	
		func appendTag(tag: String) {
				RealmManager.sharedInstance.appendTagObject(object: self, tag: tag)
		}
	
		func editColor(selectedColorId: String) {
				RealmManager.sharedInstance.editColorObject(object: self, selectedColorId: selectedColorId)
		}
}

class Tag: Object {
    @objc dynamic var id: String?
    @objc dynamic var tagName: String?
}

class Color: Object {
    @objc dynamic var id: String?
    @objc dynamic var colorHexString: String?
}
