import Foundation

let HISTORY_PATH = "/Caches/Metadata/Safari/History"
let MAX_RESULTS = 20

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
}

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
        sub = url
        uid = url
        text = url
        arg = historyItem.plistURL.path!
        icon = AlfredResult.SafariIconPath
    }
    
    func toXML() -> NSXMLElement {
        let resultXML = NSXMLElement(name: "item")
        resultXML.addAttribute(NSXMLNode.attributeWithName("uid", stringValue: uid) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("arg", stringValue: arg) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("title", stringValue: title) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("subtitle", stringValue: sub) as! NSXMLNode)
        resultXML.addChild(NSXMLNode.elementWithName("icon", stringValue: icon) as! NSXMLNode)
        let copyTextNode = NSXMLElement.elementWithName("text", stringValue: text)
        copyTextNode.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "copy") as! NSXMLNode)
        resultXML.addChild(copyTextNode as! NSXMLNode)
        let largeTypeNode = NSXMLElement.elementWithName("text", stringValue: text)
        largeTypeNode.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "largetype") as! NSXMLNode)
        resultXML.addChild(largeTypeNode as! NSXMLNode)
        return resultXML
    }
}

var outputPipe = NSPipe()
var totalString = ""
func captureStandardOutput(task: NSTask) {
    task.standardOutput = outputPipe
    outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    
    NSNotificationCenter.defaultCenter().addObserverForName(
        NSFileHandleDataAvailableNotification,
        object: outputPipe.fileHandleForReading ,
        queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: NSUTF8StringEncoding) ?? ""
            
            dispatch_async(
                dispatch_get_main_queue(), {
                    let previousOutput = totalString ?? ""
                    let nextOutput = previousOutput + "\n" + outputString
                    totalString = nextOutput
                    let paths = totalString.componentsSeparatedByString("\n").filter {
                        component in
                        return component != ""
                    }
                    showItemsAtPaths(paths)
            })
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }
}

func shell(args: [String]) -> Int32 {
    let task = NSTask()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    captureStandardOutput(task)
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func showItemsAtPaths(paths: [String]) {
    var results = [AlfredResult]()
    let root = NSXMLElement(name: "items")
    for path in paths {
        let item = HistoryItem(fromPlistAtURL: NSURL.fileURLWithPath(path))
        guard let alfredResult = item.alfredResult() else {
            continue
        }
        let resultXML = alfredResult.toXML()
        root.addChild(resultXML)
        
        results.append(alfredResult)
        if results.count >= MAX_RESULTS {
            break
        }
    }
    
    let xml = NSXMLDocument(rootElement: root)
    print(xml.XMLStringWithOptions(NSXMLNodePrettyPrint))
}

let fileManager = NSFileManager()
let libraryURL = try! fileManager.URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
let fullPath = libraryURL.path!.stringByAppendingString(HISTORY_PATH)
var mdfindArgs = ["mdfind", "-onlyin", fullPath]
let concattedArgs = Process.arguments.dropFirst()
if let args = concattedArgs.first {
    let splittedArgs = args.componentsSeparatedByString(" ")
    mdfindArgs.appendContentsOf(splittedArgs)
    shell(mdfindArgs)
}