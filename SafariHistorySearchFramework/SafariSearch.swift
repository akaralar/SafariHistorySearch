import Foundation


public class Search: NSObject {

    static let HISTORY_PATH = "/Caches/Metadata/Safari/History"
    static let MAX_RESULTS = 20

    static var outputPipe = NSPipe()
    static var totalString = ""
    static var args = ""

    public static func start(arguments: Array<String>) {
        outputPipe = NSPipe()
        let fileManager = NSFileManager()
        let libraryURL = try! fileManager.URLForDirectory(.LibraryDirectory,
                                                          inDomain: .UserDomainMask,
                                                          appropriateForURL: nil,
                                                          create: false)
        let fullPath = libraryURL.path!.stringByAppendingString(HISTORY_PATH)
        var mdfindArgs = ["mdfind", "-onlyin", fullPath]
        let concattedArgs = arguments.dropFirst()
        mdfindArgs.appendContentsOf(concattedArgs)

        args = concattedArgs.reduce("") { total, next in
            return total + next + " "
        }.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
        shell(mdfindArgs)
    }

    static func shell(args: [String]) -> Int32 {
        let task = NSTask()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        captureStandardOutput(task)
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }

    static func captureStandardOutput(task: NSTask) {
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
                        task.terminate()
                })
        }
        
    }

    static func showItemsAtPaths(paths: [String]) {
        var results = [AlfredResult]()
        for path in paths {
            let item = HistoryItem(fromPlistAtURL: NSURL.fileURLWithPath(path))
            guard let alfredResult = item.alfredResult() else {
                continue
            }

            results.append(alfredResult)
            if results.count >= MAX_RESULTS {
                break
            }
        }

        let root = ["items": results.map { $0.toDictionary() }]

        let jsonData = try! NSJSONSerialization.dataWithJSONObject(root, options: .PrettyPrinted)
        let json = NSString(data: jsonData, encoding: NSUTF8StringEncoding)!
        print(json)
    }
}
