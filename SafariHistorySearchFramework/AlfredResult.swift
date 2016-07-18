//
//  AlfredResult.swift
//  SafariHistorySearchFramework
//
//  Created by Ahmet Karalar on 18/07/16.
//  Copyright © 2016 Ahmet Karalar. All rights reserved.
//

import Foundation

let formatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.timeStyle = .NoStyle
    formatter.dateStyle = .ShortStyle
    return formatter
}()

struct AlfredResult {
    static let SafariIconPath = "compass.png"

    let uid: String
    let arg: String
    let title: String
    let sub: String
    let icon: String
    let text: String
    let type: String = "file"

    init(fromHistoryItem historyItem: HistoryItem) {
        let url = historyItem.url!.absoluteString
        title = historyItem.name ?? "<TITLE_MISSING>"
        sub = formatter.stringFromDate(historyItem.lastModified) + " | " + url
        uid = url
        text = url
        arg = historyItem.plistURL.path!
        icon = AlfredResult.SafariIconPath
    }

    func toDictionary() -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        dict["uid"] = uid
        dict["title"] = title
        dict["subtitle"] = sub
        dict["arg"] = uid
//        dict["icon"] = ["type": "fileicon", "path": icon]
        dict["type"] = type
        dict["text"] = ["copy": text, "largetype": text]
        return dict
    }
}
