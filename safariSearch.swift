#!/usr/bin/env swift

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


//for url in historyEnumerator! {
//    print(url)
//}
//while let currentObject = historyEnumerator?.nextObject() {
//    print(currentObject)
//}

