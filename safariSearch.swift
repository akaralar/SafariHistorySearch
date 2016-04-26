
import Foundation

let HISTORY_PATH = "/Caches/Metadata/Safari/History"
let SAFARI_ICON_PATH = "compass.png"
let MAX_RESULTS = 10
let EscapeMap = ["&": "&amp",
                 "\"": "&quot",
                 "'": "&apos",
                 "<": "&lt",
                 ">": "&gt"]

struct HistoryItem {
    let url: NSURL?
    let name: String?
    let fullText: String?
    
    init(fromPlist plist: AnyObject) {
        
        if let urlString = plist.objectForKey("URL") as? String {
            url = NSURL(string: urlString)
        }
        else {
            url = nil
        }
        name = plist.objectForKey("Name") as? String
        fullText = plist.objectForKey("Full Page Text") as? String
    }
    
    func alfredResult() -> AlfredResult? {
        return url != nil ? AlfredResult(fromHistoryItem: self) : nil
    }
}

struct AlfredResult {
    var uid: String  = ""
    var arg: String  = ""
    var title: String  = ""
    var sub: String  = ""
    var icon: String  = ""
    
    init(fromHistoryItem historyItem: HistoryItem) {
        let url = historyItem.url!.absoluteString
        title = historyItem.name ?? "<TITLE_MISSING>"
        sub = url
        uid = url
        arg = url
        icon = SAFARI_ICON_PATH
    }
    
    func toXML() -> NSXMLElement {
        let resultXML = NSXMLElement(name: "item")
        resultXML.addAttribute(NSXMLNode.attributeWithName("uidid", stringValue: uid) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("arg", stringValue: arg) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("title", stringValue: title) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("sub", stringValue: sub) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("icon", stringValue: icon) as! NSXMLNode)
        return resultXML
    }
    
}

func escapedString(unescaped: String) -> String {
    var escaped = unescaped
    for (key, value) in EscapeMap {
        escaped = escaped.stringByReplacingOccurrencesOfString(key, withString: value)
    }
    return escaped
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

var results = [AlfredResult]()
let root = NSXMLElement(name: "items")
for url in clipped {
    let data = NSData.init(contentsOfURL: url as! NSURL)
    let plist = try! NSPropertyListSerialization.propertyListWithData(data!, options: .Immutable, format: nil)
    let item = HistoryItem(fromPlist: plist)
    
    guard let alfredResult = item.alfredResult() else {
        continue
    }
    
    results.append(alfredResult)
    let resultXML = alfredResult.toXML()
    root.addChild(resultXML)
}

var xml = NSXMLDocument(rootElement: root)
print(xml.XMLStringWithOptions(NSXMLNodePrettyPrint))
