
import Foundation

let HISTORY_PATH = "/Caches/Metadata/Safari/History"

struct HistoryItem {
    let url: NSURL
    let name: String
    let fullText: String?
    
    init(fromPlist plist: AnyObject) {
        name = plist.objectForKey("Name") as! String
        url = NSURL(string: plist.objectForKey("URL") as! String)!
        fullText = plist.objectForKey("Full Page Text") as? String
    }
}

let fileManager = NSFileManager()
let libraryURL = try! fileManager.URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
let fullPath = libraryURL.path!.stringByAppendingString(HISTORY_PATH)
let fullURL = NSURL.fileURLWithPath(fullPath)
let keys = [NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey]
let historyEnumerator = fileManager.enumeratorAtURL(fullURL, includingPropertiesForKeys: keys, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles) { (url, error) -> Bool in
        print("\(url), \(error)")
        return false
    }

let all = historyEnumerator!.allObjects
let clipped = all.prefixUpTo(10)

for url in clipped {
    let data = NSData.init(contentsOfURL: url as! NSURL)
    let plist = try! NSPropertyListSerialization.propertyListWithData(data!, options: .Immutable, format: nil)
    let item = HistoryItem.init(fromPlist: plist)
}




