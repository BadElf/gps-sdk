# EADemo

1.2
Updated for iOS 9. Implements Storyboard support.

## Requirements

### Building

Xcode 7.3
The sample was built using Xcode 7.3 on OS X 10.11.5 with the 1OS 9 SDK.

### Runtime

iOS 9.x
The sample requires iOS 8.0, but the core code works fine on all versions of iOS to iOS 7.

### Packing List

The sample contains the following items:
* README.md -- This file.
* LICENSE.txt — The standard sample code license.
* EADemo.xcodeproj -- An Xcode project for the sample.
* EADemo_Prefix.pch -- Prefix header for all source files in the EADemo project.
* Info.plist -- The application Info.plist file.
* EADSessionController.[hm] -- Provides an interface for communication with an EASession. It is also the delegate for the EASession input and output stream objects.
* EADSessionTransferViewController.[hm] -- A view controller to allow transferring data to and from an accessory form the UI.
* EADemoAppDelegate.[hm] -- A delegate object for the User Interface.
* RootViewController.[hm] -- A table view controller for watching the device come and go.

## Using the sample

Before you build the sample, open Info.plist and enter the protocolString for your accessory in the "Supported external accessory protocols" property. If the protocolString is not registered in the Info.plist, the attempt to open an EASession with the accessory will fail.
The sample can be used with any Made For iPod (MFI) accessory designed for use with the External Accessory Framework. The application will display all attached External Accessories in the "Accessories" table view, provide information registered by the MFI accessory, and provides methods to send and receive data to the accessory. Information about MFI accessories is available to licensees of the MFI program. You can learn more about the MFI program at the Apple Developer Connection "Made For iPod Program" web page <http://developer.apple.com/ipod/index.html>.
When the MFI accessory is attached, iOS reads the MFI accessory provided information that includes the supported protocol strings. The system searches for a matching protocol string in the UISupportedExternalAccessoryProtocols array of the Info.plist of all the installed applications. If no matching protocol string is found, iOS raises the "Application Not Installed" alert. You can modify the UISupportedExternalAccessoryProtocols property in the Info.plist to include the protocol string registered by your accessory, to keep the system from presenting the "Application Not Installed" alert on accessory attachment.
At the "Accessories" table view, the name of all attached MFI accessories are displayed. Click on the accessory name to see a list of supported protocols. Under iOS 5+, if the application has the protocol string defined in the UISupportedExternalAccessoryProtocols property, then select the protocol, and the application will use the protocol to open a session for communication with the accessory. If the protocol has not been previously defined, an alert is present to indicate that the protocolString is not defined in the Info.plist, and the session is be opened.
Under iOS 4.x and 3.2, the External Accessory Framework allows a connection to be opened regardless whether the protocol string is defined in the UISupportedExternalAccessoryProtocols property.
The Protocol table view provides options for three different ways to send data to the accessory. There is also a counter to display the number of bytes received from the accessory. The three buttons and the methods that are called are
"Send String"   - sendString - sends the string entered in the UITextField it's associated with in the view to the accessory.
"Send Hex Data" - sendHex - sends the string entered in the UITextField it's associated with in the view interpreted as a hex byte sequence to the accessory.
"Send 10K"      - send10K - sends 10K bytes of incrementing 8-bit values (0 to 255) to the accessory.
If the accessory is detached, the application will detect this action and reset itself to the main Accessories table view. When no accessory is attached, the main screen will display the message "No Accessories Connected".
Under iOS 5, when EADemo is put into the background, the application will continue to support an open connection. iOS 5 looks for the "external-accessory" string in the UIBackgroundModes key, and will support open sessions with an accessory while in the background. If the "external-accessory" is not declared, then when the application is put into the background, it will receive the didDisconnectNotification for each attached accessory as it does under iOS 4.x and 3.2.
Under iOS 4.x and earlier, when EADemo is put into the background, the application will receive the didDisconnectNotification for attached accessories. While in the background, there is no support for open sessions. When the application is brought to the foreground, it will receive a didConnectNotification for each attached accessory.
For more information about Multitasking support, please read the "iOS Application Programming Guide" sections on "Multitasking" and "Executing Code in the Background".

For iOS 5.0
iOS 5.0 provides background session support to process incoming data from an external accessory. Including the UIBackgroundModes key with the external-accessory value in your application’s Info.plist file keeps your accessory sessions open even when your application is suspended. (Prior to iOS 5, these sessions were closed automatically at suspend time.) When new data arrives for a given session, a suspended app is woken up and given time to process the new data. This type of behavior is designed for applications that work with accessories that need to deliver data at regular intervals.
The iOS 5.0 application which sets background support will not receive a didDisconnectNotification when the application moves to the background. The session will stay open and continue to receive new data from the accessory via the handleEvent method. The application must follow the standard guidelines as documented in the App Programming Guide for iOS <https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html>
When the application is active and an MFI accessory is attached, you may observe the accessory momentarily displayed in the table view. The application has received the EAAccessoryDidConnectNotification but the accessory identification / authentication process is incomplete. The accessory will note that the protocolStrings is empty for this event. The accessory will receive the EAAccessoryDidDisconnectNotification event. Moments later, the application will receive the EAAccessoryDidConnectNotification, this time the protocolStrings array will contain the protocolString(s) registered by the accessory.

## Version History
1.0 - First shipping version
1.1 - (Feb 2012) - implemented background support and check for registered protocolString
1.2 - (June 2016) - fixed crash in iOS 9 and added Storyboard support.
If you find any problems with this sample, please file a bug against it.

<http://developer.apple.com/bugreporter/>

Apple Developer Technical Support
Core OS/Hardware
Copyright (C) 2016 Apple Inc. All rights reserved.

