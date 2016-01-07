//
//  MaintenanceViewController.swift
//  metaapp
//
//  Created by MM on 5/18/15.
//  Copyright (c) 2015 MM. All rights reserved.
//

import UIKit

class MaintenanceViewController: UIViewController, PTPusherDelegate {
    
    var pusherClient: PTPusher = PTPusher()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Pusher
        pusherClient = PTPusher.pusherWithKey("a071efcffc1c37bb35c7", delegate: self, encrypted:true) as! PTPusher
        
        var channel: PTPusherChannel = pusherClient.subscribeToChannelNamed("metaapp_channel") as PTPusherChannel
        
        channel.bindToEventNamed("maintenance_event", handleWithBlock: { channelEvent in
            var message = channelEvent.data.objectForKey("message") as! String

            if (message == "refresh") {
                println("got refresh")
                self.performSegueWithIdentifier("goToActiveMode", sender: nil)
            }
        })
        
        pusherClient.connect()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

