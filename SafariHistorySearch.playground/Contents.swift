
import Foundation

let HISTORY_PATH = "/Caches/Metadata/Safari/History"
let MAX_RESULTS = 10

struct HistoryItem {
    let url: NSURL?
    let name: String?
    let fullText: String?
    let plistURL: NSURL
    
    init(fromPlistAtURL plistUrl: NSURL) {
        func plistAt(url: NSURL) -> AnyObject {
            let data = NSData.init(contentsOfURL: url)
            return try! NSPropertyListSerialization.propertyListWithData(data!, options: .Immutable, format: nil)
        }
        plistURL = plistUrl
        let plist = plistAt(plistUrl)
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
    
    func contains(queries: [String]) -> Bool {
        for query in queries {
            if !contains(query) {
                return false
            }
        }
        return true
    }
    
    func contains(query: String) -> Bool {
        return matches(query, inString: self.name) ||
            matches(query, inString: self.url?.path) ||
            matches(query, inString: self.fullText)
    }
    
    func matches(query: String, inString string: String?) -> Bool {
        guard let stringToSearch = string else {
            return false
        }
        
        return stringToSearch.containsString(query)
    }
}

struct AlfredResult {
    static let SafariIconPath = "compass.png"
    
    let uid: String
    let arg: String
    let title: String
    let sub: String
    let icon: String
    let type: String = "file"
    
    init(fromHistoryItem historyItem: HistoryItem) {
        let url = historyItem.url!.absoluteString
        title = historyItem.name ?? "<TITLE_MISSING>"
        sub = url
        uid = url
        arg = historyItem.plistURL.path!
        icon = AlfredResult.SafariIconPath
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

let fileManager = NSFileManager()
let libraryURL = try! fileManager.URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
let fullPath = libraryURL.path!.stringByAppendingString(HISTORY_PATH)
let fullURL = NSURL.fileURLWithPath(fullPath)
let keys = [NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey]
let historyEnumerator = fileManager.enumeratorAtURL(fullURL, includingPropertiesForKeys: keys, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)

var results = [AlfredResult]()
let root = NSXMLElement(name: "items")

let args = Process.arguments.dropFirst()

for url in historyEnumerator! {
    let item = HistoryItem(fromPlistAtURL: url as! NSURL)
    guard let alfredResult = item.alfredResult() where item.contains(Array(args)) else {
        continue
    }
    
    results.append(alfredResult)
    
    let resultXML = alfredResult.toXML()
    root.addChild(resultXML)
    
    if results.count >= MAX_RESULTS {
        break
    }
}

var xml = NSXMLDocument(rootElement: root)
print(xml.XMLStringWithOptions(NSXMLNodePrettyPrint))
