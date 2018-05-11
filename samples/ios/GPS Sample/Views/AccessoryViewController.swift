/*
 Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that shows the MFi detected accessory information (i.e. model, serial number and firmware revision)
 */

import UIKit

class AccessoryViewController: UITableViewController {
    
    let sessionController = SessionController.sharedController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = sessionController._accessory?.modelNumber
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
        return 5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccessoryCell", for: indexPath)

        // Configure the cell...
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Name"
            cell.detailTextLabel?.text = sessionController._accessory?.name
        case 1:
            cell.textLabel?.text = "Model #"
            cell.detailTextLabel?.text = sessionController._accessory?.modelNumber
        case 2:
            cell.textLabel?.text = "Serial #"
            cell.detailTextLabel?.text = sessionController._accessory?.serialNumber
        case 3:
            cell.textLabel?.text = "Hardware"
            cell.detailTextLabel?.text = sessionController._accessory?.hardwareRevision
        case 4:
            cell.textLabel?.text = "Firmware"
            cell.detailTextLabel?.text = sessionController._accessory?.firmwareRevision
            
        default:
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = ""
        }

        return cell
    }

}
