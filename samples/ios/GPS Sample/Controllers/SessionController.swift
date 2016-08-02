/*
 Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Controller for managing connected accessory and communicating with the accessory via NSInput & NSOutput streams.
 */

import UIKit
import ExternalAccessory

class SessionController: NSObject, EAAccessoryDelegate, NSStreamDelegate {

    static let sharedController = SessionController()
    var _accessory: EAAccessory?
    var _session: EASession?
    var _protocolString: String?
    var _writeData: NSMutableData?
    var _readData: NSMutableData?
    var _dataAsString: NSString?
    
    // MARK: Controller Setup
    
    func setupController(forAccessory accessory: EAAccessory, withProtocolString protocolString: String) {
        _accessory = accessory
        _protocolString = protocolString
    }
    
    // MARK: Opening & Closing Sessions
    
    func openSession() -> Bool {
        _accessory?.delegate = self
        _session = EASession(accessory: _accessory!, forProtocol: _protocolString!)
        
        if _session != nil {
            _session?.inputStream?.delegate = self
            _session?.inputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            _session?.inputStream?.open()
            
            _session?.outputStream?.delegate = self
            _session?.outputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            _session?.outputStream?.open()
        } else {
            print("Failed to create session")
        }
        
        return _session != nil
    }
    
    func closeSession() {
        
        _session?.inputStream?.close()
        _session?.inputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        _session?.inputStream?.delegate = nil
        
        _session?.outputStream?.close()
        _session?.outputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        _session?.outputStream?.delegate = nil
        
        _session = nil
        _writeData = nil
        _readData = nil
    }
    
    // MARK: Write & Read Data
    
    func writeData(data: NSData) {
        if _writeData == nil {
            _writeData = NSMutableData()
        }
        
        _writeData?.appendData(data)
        self.writeData()
    }
    
    func readData(bytesToRead: Int) -> NSData {
        
        var data: NSData?
        if _readData?.length >= bytesToRead {
            let range = NSMakeRange(0, bytesToRead)
            data = _readData?.subdataWithRange(range)
            _readData?.replaceBytesInRange(range, withBytes: nil, length: 0)
        }
        
        return data!
    }
    
    func readBytesAvailable() -> Int {
        return (_readData?.length)!
    }
    
    // MARK: - Helpers
    func updateReadData() {
        let bufferSize = 128
        var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
        
        while _session?.inputStream?.hasBytesAvailable == true {
            let bytesRead = _session?.inputStream?.read(&buffer, maxLength: bufferSize)
            if _readData == nil {
                _readData = NSMutableData()
            }
            _readData?.appendBytes(buffer, length: bytesRead!)
            _dataAsString = NSString(bytes: buffer, length: bytesRead!, encoding: NSUTF8StringEncoding)
            NSNotificationCenter.defaultCenter().postNotificationName("BESessionDataReceivedNotification", object: nil)
        }
    }
    
    private func writeData() {
        while _session?.outputStream?.hasSpaceAvailable == true && _writeData?.length > 0 {
            var buffer = [UInt8](count: _writeData!.length, repeatedValue: 0)
            _writeData?.getBytes(&buffer, length: (_writeData?.length)!)
            let bytesWritten = _session?.outputStream?.write(&buffer, maxLength: _writeData!.length)
            if bytesWritten == -1 {
                print("Write Error")
                return
            } else if bytesWritten > 0 {
                _writeData?.replaceBytesInRange(NSMakeRange(0, bytesWritten!), withBytes: nil, length: 0)
            }
        }
    }
    
    // MARK: - EAAcessoryDelegate
    
    func accessoryDidDisconnect(accessory: EAAccessory) {
        // Accessory diconnected from iOS, updating accordingly
    }
    
    // MARK: - NSStreamDelegateEventExtensions
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.None:
            break
        case NSStreamEvent.OpenCompleted:
            break
        case NSStreamEvent.HasBytesAvailable:
            // Read Data
            updateReadData()
            break
        case NSStreamEvent.HasSpaceAvailable:
            // Write Data
            self.writeData()
            break
        case NSStreamEvent.ErrorOccurred:
            break
        case NSStreamEvent.EndEncountered:
            break
            
        default:
            break
        }
    }
}
