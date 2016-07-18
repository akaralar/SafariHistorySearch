//
//  HistoryItem.swift
//  SafariHistorySearchFramework
//
//  Created by Ahmet Karalar on 18/07/16.
//  Copyright © 2016 Ahmet Karalar. All rights reserved.
//

import Foundation

struct HistoryItem {
    let url: NSURL?
    let name: String?
    let fullText: String?
    let plistURL: NSURL
    let lastModified: NSDate

    init(fromPlistAtURL plistUrl: NSURL) {

        func plistAt(url: NSURL) -> AnyObject {
            let data = NSData.init(contentsOfURL: url)
            return try! NSPropertyListSerialization.propertyListWithData(data!, options: .Immutable, format: nil)
        }

        plistURL = plistUrl
        let plist = plistAt(plistUrl)
        if let urlString = plist.objectForKey("URL") as? String {
            url = NSURL(string: urlString)
        } else {
            url = nil
        }
        name = plist.objectForKey("Name") as? String
        fullText = plist.objectForKey("Full Page Text") as? String
        
        let attrs = try! NSFileManager.defaultManager().attributesOfItemAtPath(plistUrl.path!)
        lastModified = attrs[NSFileModificationDate] as! NSDate
    }

    func alfredResult() -> AlfredResult? {
        return url != nil ? AlfredResult(fromHistoryItem: self) : nil
    }
}
