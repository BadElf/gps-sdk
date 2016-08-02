/*
 Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Table View controller that lists the detected MFi accessories and opens sessions for them.
 */

import UIKit
import ExternalAccessory

class DetectionTableViewController: UITableViewController {

    var sessionController: SessionController!
    var accessoryList: [EAAccessory]?
    var selectedAccessory: EAAccessory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accessoryDidConnect), name: EAAccessoryDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(accessoryDidDisconnect), name: EAAccessoryDidDisconnectNotification, object: nil)
        EAAccessoryManager.sharedAccessoryManager().registerForLocalNotifications()
        
        sessionController = SessionController.sharedController
        accessoryList = EAAccessoryManager.sharedAccessoryManager().connectedAccessories
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: EAAccessoryDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: EAAccessoryDidDisconnectNotification, object: nil)
        
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessoryList!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AccessoryCell", forIndexPath: indexPath)

        // Configure the cell...
        
        var accessoryName = accessoryList?[indexPath.row].name
        if accessoryName == nil  || accessoryName == "" {
            accessoryName = "Unknown Accessory"
        }
        
        cell.textLabel?.text = accessoryName

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        selectedAccessory = accessoryList![indexPath.row]
        
        sessionController.setupController(forAccessory: selectedAccessory!, withProtocolString: (selectedAccessory?.protocolStrings[0])!)
        
        performSegueWithIdentifier("showAccessoryConfig", sender: nil)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    // MARK: - EAAccessoryNotification Handlers
    
    func accessoryDidConnect(notificaton: NSNotification) {
        let connectedAccessory = notificaton.userInfo![EAAccessoryKey]
        accessoryList?.append(connectedAccessory as! EAAccessory)
        
        let indexPath = NSIndexPath(forRow: (accessoryList!.count - 1), inSection: 0)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func accessoryDidDisconnect(notification: NSNotification) {
        let disconnectedAccessory = notification.userInfo![EAAccessoryKey]
        
        if selectedAccessory != nil && disconnectedAccessory?.connectionID == selectedAccessory?.connectionID {
            
        }
        
        var disconnectedAccessoryIndex = 0
        for accessory in accessoryList! {
            if disconnectedAccessory?.connectionID == accessory.connectionID {
                break
            }
            disconnectedAccessoryIndex += 1
        }
        
        if disconnectedAccessoryIndex < accessoryList?.count {
            accessoryList?.removeAtIndex(disconnectedAccessoryIndex)
            let indexPath = NSIndexPath(forRow: disconnectedAccessoryIndex, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
        } else {
            print("Could not find disconnected accessories in list")
        }
        
        if accessoryList?.count == 0 {
            
        }
    }

}
