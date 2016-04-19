
import Foundation

let HISTORY_PATH = "/Caches/Metadata/Safari/History"

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
    let plist = NSPropertyListSerialization.propertyListFromData(data!, mutabilityOption: .Immutable, format: nil, errorDescription: nil)
    print("plist: \(plist!.objectForKey("Full Page Text"))\n")
}

//for url in historyEnumerator! {
//    print(url)
//}

//while let currentObject: AnyObject = historyEnumerator?.nextObject() {
//    print(currentObject.filename)
//}

//let enumerator = fileManager.enumeratorAtPath(fullPath)

//for url in enumerator! {
//    print(url)
//}




