import UIKit
import CoreSpotlight
import MobileCoreServices

extension UIColor {
    class func color(hexString: String, alpha: CGFloat) -> UIColor {
        let processedString = NSString(string: hexString).stringByReplacingOccurrencesOfString("#", withString: "")
        let scanner = NSScanner(string: processedString as String)
        var color: UInt32 = 0
        if scanner.scanHexInt(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        } else {
            assert(false, "Invalid hex string")
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundTaskIdentifier = UIBackgroundTaskInvalid

    func applicationDidEnterBackground(application: UIApplication) {
        if (UIDevice.currentDevice().systemVersion as NSString).integerValue < 9 {
            return
        }

        if !CSSearchableIndex.isIndexingAvailable() {
            return
        }

        if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            return
        }

        var searchableItems = [CSSearchableItem]()

        for _ in 0..<10 {
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)

            let rect = CGRectMake(0.0, 0.0, 180.0, 270.0);

            UIGraphicsBeginImageContext(rect.size);

            let context = UIGraphicsGetCurrentContext();

            let red = arc4random_uniform(255)
            let green = arc4random_uniform(255)
            let blue = arc4random_uniform(255)
            let hexString = String(NSString(format: "#%02x%02x%02x", red, green, blue))
            let color = UIColor.color(hexString, alpha: 1.0)
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillRect(context, rect);

            let image = UIGraphicsGetImageFromCurrentImageContext();

            UIGraphicsEndImageContext();

            if image != nil {
                let thumbnailData = UIImagePNGRepresentation(image)
                attributeSet.thumbnailData = thumbnailData
            }

            let title = hexString
            let contentDescription = "Color R:" + String(red) + " " + "G:" + String(green) + " " + "B:" + String(blue)
            attributeSet.title = title
            attributeSet.contentDescription = contentDescription
            attributeSet.keywords = [title, contentDescription]

            attributeSet.identifier = hexString
            attributeSet.relatedUniqueIdentifier = hexString

            attributeSet.latitude = 37.375709
            attributeSet.longitude = -122.03430
            attributeSet.supportsNavigation = 1

            attributeSet.phoneNumbers = ["xxxxxxxxxxx"]
            attributeSet.supportsPhoneCall = 1
            
            attributeSet.languages = ["en", "ja"]
            
            let domainIdentifier = "com.core-spotlight-search-sample"
            let searchableItem = CSSearchableItem(uniqueIdentifier: attributeSet.identifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)

            searchableItems.append(searchableItem)
        }

        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ 
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
        })

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let searchableIndex = CSSearchableIndex(name: "com.core-spotlight-search-sample-searchable-index")
            searchableIndex.fetchLastClientStateWithCompletionHandler({ (clientState, error) in
                if let data = clientState {
                    let lastIndexDate = NSKeyedUnarchiver.unarchiveObjectWithData(data)
                    print(lastIndexDate)
                }
                if error != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                    }
                } else {
                    searchableIndex.beginIndexBatch()
                    searchableIndex.indexSearchableItems(searchableItems, completionHandler: nil)
                    let lastIndexDate = NSKeyedArchiver.archivedDataWithRootObject(NSDate())
                    searchableIndex.endIndexBatchWithClientState(lastIndexDate, completionHandler: { (error) in
                        dispatch_async(dispatch_get_main_queue()) {
                            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                        }
                    })
                }
            })
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            application.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
    }

    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        if let userInfo = userActivity.userInfo,
            let hexString = userInfo[CSSearchableItemActivityIdentifier] as? String {
            let color = UIColor.color(hexString, alpha: 1.0)
            self.window?.rootViewController?.view.backgroundColor = color
        }
        return true
    }
}

