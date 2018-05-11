/*
 Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Table View controller that lists the detected MFi accessories and opens sessions for them.
 */

import UIKit
import ExternalAccessory
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class DetectionTableViewController: UITableViewController {

    var sessionController: SessionController!
    var accessoryList: [EAAccessory]?
    var selectedAccessory: EAAccessory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidConnect), name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidDisconnect), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
        EAAccessoryManager.shared().registerForLocalNotifications()
        
        sessionController = SessionController.sharedController
        accessoryList = EAAccessoryManager.shared().connectedAccessories
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
        
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accessoryList!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccessoryCell", for: indexPath)

        // Configure the cell...
        
        var accessoryName = accessoryList?[indexPath.row].name
        if accessoryName == nil  || accessoryName == "" {
            accessoryName = "Unknown Accessory"
        }
        
        cell.textLabel?.text = accessoryName

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedAccessory = accessoryList![indexPath.row]
        
        sessionController.setupController(forAccessory: selectedAccessory!, withProtocolString: (selectedAccessory?.protocolStrings[0])!)
        
        performSegue(withIdentifier: "showAccessoryConfig", sender: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    // MARK: - EAAccessoryNotification Handlers
    
    func accessoryDidConnect(_ notificaton: Notification) {
        let connectedAccessory = notificaton.userInfo![EAAccessoryKey]
        accessoryList?.append(connectedAccessory as! EAAccessory)
        
        let indexPath = IndexPath(row: (accessoryList!.count - 1), section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func accessoryDidDisconnect(_ notification: Notification) {
        let disconnectedAccessory = notification.userInfo![EAAccessoryKey]
        
        if selectedAccessory != nil && (disconnectedAccessory as AnyObject).connectionID == selectedAccessory?.connectionID {
            
        }
        
        var disconnectedAccessoryIndex = 0
        for accessory in accessoryList! {
            if (disconnectedAccessory as AnyObject).connectionID == accessory.connectionID {
                break
            }
            disconnectedAccessoryIndex += 1
        }
        
        if disconnectedAccessoryIndex < accessoryList?.count {
            accessoryList?.remove(at: disconnectedAccessoryIndex)
            let indexPath = IndexPath(row: disconnectedAccessoryIndex, section: 0)
            tableView.deleteRows(at: [indexPath], with: .right)
        } else {
            print("Could not find disconnected accessories in list")
        }
        
        if accessoryList?.count == 0 {
            
        }
    }

}
