//
//  DataFetcher.swift
//  dashboardmonirmamoun
//
//  Created by MM on 5/6/15.
//  Copyright (c) 2015 MM. All rights reserved.
//

import Foundation

protocol DataFetcherDelegate {
    func fetchSuccess(launchScreen: String, storyboard: NSDictionary, url: String)
    func fetchFailure(message: String, url: String)
}


class DataFetcher: NSObject, NSURLConnectionDataDelegate {
    let url: String
    var receivedData: NSMutableData!
    let delegate: DataFetcherDelegate
    
    init(url: String, delegate: DataFetcherDelegate) {
        self.url = url
        self.delegate = delegate
        super.init()
        
        if let url = NSURL(string: url) {
            let urlRequest = NSURLRequest(URL: url)
            NSURLConnection(request: urlRequest, delegate: self)
        } else {
            reportFailure("Could not create NSURL")
        }
    }
    
    deinit {
        println("The Data Fetcher for '\(url)' is being deallocated")
    }
    
    func reportFailure(message: String) {
        delegate.fetchFailure(message, url: url)
    }
    
    /* START NSURLConnectionDataDelegate protocol methods */
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
       receivedData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
       receivedData.appendData(data)
    }

    func connectionDidFinishLoading(connection: NSURLConnection) {
        convertDataToJSON()
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        reportFailure(error.description)
    }
    
    /* END NSURLConnectionDataDelegate protocol methods */
    
    func convertDataToJSON() {
        var error : NSError?
        
        
        let jsonObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(receivedData, options: NSJSONReadingOptions.AllowFragments, error: &error)
        
        if error == nil {
            if let dataDict = jsonObject as? NSDictionary {
                //println("\(dataDict)")
                let launchScreen = dataDict["launchScreen"] as? String
                let storyboard = dataDict["storyboard"] as? NSDictionary
                
                delegate.fetchSuccess(launchScreen!, storyboard: storyboard!, url: url)
                
            } else {
                reportFailure("Error: converted JSON data is not an NSDictionary")
            }
        } else {
            reportFailure("Error: NSJSONSerialization couldn't convert receivedData")
        }
    }
}