//
//  ViewController.swift
//  metaapp
//
//  Created by MM on 5/18/15.
//  Copyright (c) 2015 MM. All rights reserved.
//

import UIKit


// extend UIButton
var AssociatedObjectHandle: UInt8 = 0

extension UIButton {
    var linkToScreen:String {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as! String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
}

class ViewController: UIViewController, DataFetcherDelegate, PTPusherDelegate {
    
    var metaLaunchscreen: String?
    var metaStoryboard: NSDictionary?
    
    var pusherClient: PTPusher = PTPusher()
    
    //var channel: PTPusherChannel?
    
    @IBOutlet weak var mainViewLabel: UILabel?
    
    @IBOutlet weak var mainViewMessage: UITextView?
    
    @IBOutlet weak var optionsLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("view did load")
        //Pusher
        pusherClient = PTPusher.pusherWithKey("a071efcffc1c37bb35c7", delegate: self, encrypted:true) as! PTPusher
        
        
        //var presenceDelegate: PTPusher?
        var channel: PTPusherChannel = pusherClient.subscribeToChannelNamed("metaapp_channel") as PTPusherChannel

        channel.bindToEventNamed("maintenance_event", handleWithBlock: { channelEvent in
            var message = channelEvent.data.objectForKey("message") as! String
            if (message == "maintenance") {
                println("got maintenance")
                self.performSegueWithIdentifier("goToMaintenanceMode", sender: nil)
            }

        })
        
        pusherClient.connect()
        // Do any additional setup after loading the view, typically from a nib.
       
    }

    override func viewDidAppear(animated: Bool) {
         refreshMetastoryboard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func fetchSuccess(launchScreen: String, storyboard: NSDictionary, url: String) {
        println("Request: '\(url)' succeeded!")
        
        println("got launchscreen: \(launchScreen)")

        println("got storyboard: \(storyboard)")

        println("keys: \(storyboard.allKeys)")
        
        metaLaunchscreen = launchScreen
        
        metaStoryboard = storyboard
        
        initMetaStoryboardView()
        
    }
    
    // separate out datafetcher call so we can easily do a hot-update of our application
    func refreshMetastoryboard() {
        let fetcher = DataFetcher(url: "https://s3.amazonaws.com/monir/config.json", delegate: self)
    }
    
    func fetchFailure(message: String, url: String) {
        println("Request: '\(url)' failed for the following reason: '\(message)'")
    }
    
    func initMetaStoryboardView() {
        
        println("init meta: launchscreen: \(metaLaunchscreen!)")

        drawMetaStoryboardScreen(metaLaunchscreen!)
        
    }
    
    func drawMetaStoryboardScreen(screen: String) {
        
        clearMetaStoryboardScreen()
        
        mainViewLabel?.text = "Meta app screen: \(screen) \n\n"
        
        mainViewMessage?.text = getMessageForScreen(screen) as! String
        
        mainViewMessage?.textColor = hexStringToUIColor(getMessageColorForScreen(screen) as! String)

        addLinkToScreenButtons(getLinkToScreensForScreen(screen) as! NSArray)
        
    }
    
    func clearMetaStoryboardScreen() {
        
        mainViewLabel?.text = ""
        optionsLabel?.text = ""
        
        if let subviews = self.view.subviews as? [UIView] {
            for v in subviews {
                if let button = v as? UIButton {
                    button.removeFromSuperview()
                }
            }            
        }

    }
    
    @IBAction func linkToScreenButtonAction(sender: AnyObject) {
        drawMetaStoryboardScreen((sender as! UIButton).linkToScreen)
    }
    
    func addLinkToScreenButtons(linkToScreensArray: NSArray) {
        
        var buttonYOffset = 400;
        
        if linkToScreensArray.count >= 1 {
            println("OPTIONS")
            optionsLabel?.text = "You have options:"
        }
        
        // loop through linkToScreen array and generate buttons
        for linkToScreen in linkToScreensArray {
            println("Adding button:  linkToScreen: \(linkToScreen)")
            
            let button: UIButton = UIButton()
            
            button.setTitle("Go to screen: \(linkToScreen)", forState: .Normal)
            
            button.backgroundColor = UIColor.blueColor()
            
            button.setTitleColor(UIColor.yellowColor(), forState: .Normal)
            
            button.contentEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
            
            button.center = CGPoint(x: 100, y: buttonYOffset)
            
            button.sizeToFit()
            
            button.linkToScreen = linkToScreen as! String
            
            button.addTarget(self, action: "linkToScreenButtonAction:", forControlEvents: .TouchUpInside)
            
            self.view.addSubview(button)
            
            buttonYOffset += 100
        }

    }

    func getLaunchScreen() -> String {
        println("metaStoryboard \(metaStoryboard)")
        return metaStoryboard?.valueForKey("launchScreen") as! String
    }
    
    // this function is only to be called after JSON data has been fetched; so initial call comes
    // from the fetchSuccess function and subsequent calls
    func getLinkToScreensForScreen(screen: String) -> AnyObject {
        //lookup screen
        let linkToScreens: AnyObject? = (metaStoryboard!.valueForKey(screen) as! NSDictionary)["linkToScreens"]
        for linkToScreen in (linkToScreens! as! NSArray) {
            println("GOT IT: got \(screen) linkToScreen: \(linkToScreen)")
        }
        return linkToScreens!
    }

    func getMessageForScreen(screen: String) -> AnyObject {
        //lookup screen
        return (metaStoryboard!.valueForKey(screen)!.valueForKey("message"))!
    }

    func getMessageColorForScreen(screen: String) -> AnyObject {
        //lookup screen
        if let color: AnyObject = metaStoryboard!.valueForKey(screen)!.valueForKey("messageColor") {
            return color
        } else {
            return "000000" as AnyObject // return black by default if no color set
        }
    }

    // hex color func from http://stackoverflow.com/questions/24074257/how-to-use-uicolorfromrgb-value-in-swift
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 1))
        }
        
        if (count(cString) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    /* GOOD EXTRA FUNCTIONALITY (WISH LIST)
        create a protocol for metaComponents
        and any component needs to follow that protocol
        protol would include methods for
        1. returning metaComponent version number
        2. accepting workflow metadata (like linkToScreen arrays)
        3. routing workflow decisions based on user actions to central view router
    
    
    */
    
    /* reference code graveyard.

    Code for going through all keys in the metaStoryboard:

        for key in storyboard.allKeys {
            println("key: \(key)")
            let thing: AnyObject? = (storyboard.valueForKey(key as! String) as! NSDictionary)["linkToScreens"]
            println("values: \(storyboard.valueForKey(key as! String) as! NSDictionary)")
            println("thing: \(thing!)")
            for x in (thing! as! NSArray) {
                println("got a thing: \(x)")
            }
        }
    */

}

