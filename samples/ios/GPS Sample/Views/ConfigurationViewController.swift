/*
 Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that allows configuration of the protocol strings to the Bad Elf accessory.
 */

import UIKit
import ExternalAccessory

class ConfigurationViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var sessionController: SessionController!
    var accessory: EAAccessory?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Accessory"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDataReceived), name: NSNotification.Name(rawValue: "BESessionDataReceivedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidDisconnect), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
        
        sessionController = SessionController.sharedController
        
        accessory = sessionController._accessory
        sessionController.openSession()
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "BESessionDataReceivedNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
        
        sessionController.closeSession()
        
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface Actions
    
    @IBAction func segmentedControlForBasicDataDidChange(_ sender: UISegmentedControl) {
        var configString: String!
        switch sender.selectedSegmentIndex {
        case 0:
            // 1Hz Updates
            configString = "24be001105010205310132043301640d0a"
            break
        case 1:
            // 2 Hz Updates
            configString = "24be001104010206310232043301630d0a"
            break
        case 2:
            // 4 Hz Updates
            configString = "24be001107010203310432113301540d0a"
            break
        case 3:
            // 5 Hz Updates
            configString = "24be001106010204310532043301600d0a"
            break
        case 4:
            // 10 Hz Updates
            configString = "24be001108010202310a320433015b0d0a"
            break
        default:
            break
        }
        
        configureAccessoryWithString(configString)
        
    }
    
    @IBAction func segmentedControlForSatDataDidChange(_ sender: UISegmentedControl) {
        var configString: String!
        switch sender.selectedSegmentIndex {
        case 0:
            // 1Hz Updates
            configString = "24be00110b0102ff310132043302630d0a"
            break
        case 1:
            // 2 Hz Updates
            configString = "24be0011100102fa310232043302620d0a"
            break
        case 2:
            // 4 Hz Updates
            configString = "24be0011120102f8310432043302600d0a"
            break
        case 3:
            // 5 Hz Updates
            configString = "24be0011130102f73105320433025f0d0a"
            break
        case 4:
            // 10 Hz Updates
            configString = "24be0011160102f4310a320433025a0d0a"
            break
        default:
            break
        }
        
        configureAccessoryWithString(configString)
    }
    
    // MARK: - Session Updates
    
    func sessionDataReceived(_ notification: Notification) {
        
        if sessionController._dataAsString != nil {
            textView.textStorage.beginEditing()
            textView.textStorage.mutableString.appendFormat(sessionController._dataAsString!)
            textView.textStorage.endEditing()
            textView.scrollRangeToVisible(NSMakeRange(textView.textStorage.length, 0))
        }
    }

    // MARK: - EAAccessory Disconnection
    
    func accessoryDidDisconnect(_ notification: Notification) {
        if navigationController?.topViewController == self {
            let disconnectedAccessory = notification.userInfo![EAAccessoryKey]
            if (disconnectedAccessory as AnyObject).connectionID == accessory?.connectionID {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func configureAccessoryWithString(_ configString: String) {
        
        let data = configString.dataFromHexadecimalString()
        sessionController.writeData(data!)
    }

}

extension String {
    func dataFromHexadecimalString() -> Data? {
        let trimmedString = self.trimmingCharacters(in: CharacterSet(charactersIn: "<>".replacingOccurrences(of: " ", with: "")))
        
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
        
        let found = regex.firstMatch(in: trimmedString, options: [], range: NSMakeRange(0, trimmedString.characters.count))
        if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
            return nil
        }
        
        // everything ok, so now let's build NSData
        
        let data = NSMutableData(capacity: trimmedString.characters.count / 2)
        var index = trimmedString.startIndex
        while index < trimmedString.endIndex {
            let byteString = trimmedString.substring(with: (index ..< trimmedString.index(after: index)))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append([num] as [UInt8], length: 1)
            index = trimmedString.index(after: index)
        }
        
        return data as! Data
    }
}
