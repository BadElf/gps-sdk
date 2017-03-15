<h3 align="center">
  <img src="http://epo.bad-elf.com/sdk-logo.png" alt="bad-elf-sdk-logo" />
</h3>

# Bad Elf GPS SDK
=================

[![Twitter: @bad_elf](https://img.shields.io/badge/contact-@bad__elf-blue.svg?style=flat)](https://twitter.com/bad_elf)
![](https://img.shields.io/badge/license-BSD--New-green.svg)
![](https://img.shields.io/badge/version-v1.0.2-blue.svg)

Bad Elf is excited to provide developers with the protocol information and sample code to communicate with Bad Elf GPS accessories across many platforms. This SDK provides real-time and native support for the wide range of data and configurations that each Bad Elf GPS accessory supports. 

We strongly suggest developers review all the information contained here before starting to integrate the protocol or sample code into your application.

## Bad Elf Protocol Features
|---| Bad Elf |
|---|---------|
|:rocket: 	  | Fast and reliable positional data at 1-10Hz update rate |
|:wrench:   | Access extended satellite and accuracy information not available elsewhere
|:computer: | Support for iOS, Android, Windows, and any other platform via Bluetooth SPP
|:book:     | No binary SDK to integrate into your app
|:pencil2:  | Uses industry-standard NMEA sentences
|:octocat:  | Frequent firmware updates and rapid support responses


## Supported Platforms & Requirements
We have tested and provide support for our protocol on the following platforms:

* iOS
* macOS
* Android
* Windows 8.1 (Surface 2)
* Windows 10 (Surface 3)

> Your application will require a NMEA parser to effectively use the data provided from Bad Elf GPS accessories. There are many open source and 3rd party libraries available on the web.

## Supported Accessories
This SDK works with all of the Bad Elf GPS accessories listed below.  The minimum firmware level (or newer) must be installed in the accessory to ensure compatibility with all of the features documented in this SDK.

| Model Name             | Model      | Minimum Firmware Version | Connectivity    |
|------------------------|------------|--------------------------|---------------- |
| Bad Elf GPS for 30-pin    | BE-GPS-1000 | Not Supported | ---    | 
| Bad Elf GPS for Lightning | BE-GPS-1008 | v1.0.20 | iOS only via EA    |
| Bad Elf GPS Pro | BE-GPS-2200 | v2.0.90 | Bluetooth         |
| Bad Elf GPS Pro+ | BE-GPS-2300 | v2.1.40 | Bluetooth, USB         |
| Bad Elf GNSS Surveyor | BE-GPS-3300 | v2.1.40 | Bluetooth, USB         |


> If your app detects a Bad Elf GPS accessory with older firmware, you should prompt the user to perform a firmware update using the official [Bad Elf GPS App (iOS only)](https://itunes.apple.com/us/app/bad-elf-gps/id391764718?mt=8&uo=4&at=10I4Go). For non-iOS apps and users, you can point Bad Elf GPS Pro+ users to our [instructions for upgrading Bad Elf GPS Pro+ accessories via USB](https://badelf.freshdesk.com/support/solutions/articles/5000698434-update-the-firmware-directly-with-the-usb-port). And for Bad Elf Surveyor users, you can point them to these [instructions for upgrading Bad Elf Surveyor accessories via USB](https://badelf.freshdesk.com/support/solutions/articles/5000712939-update-the-firmware-directly-with-the-usb-port).  This only applies to the accessories with USB connectivity as shown above.

## Basic Configuration (iOS)
Bad Elf accessories are certified Apple MFi accessories which means there is a bit more setup with Apple devices. In order to start the flow of raw NMEA data into your app, you must first include the `ExternalAccessory.framework` into your iOS app.

The External accessory framework handles the accessory detection, opening/closing of `EASessions` and the `NSInputStream` and `NSOutputStream` events. In order to establish two way communication with a Bad Elf you must include the following in your project's Info.plist file.

### Supported Accessory Protocol Identifer
```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
	<string>com.bad-elf.gps</string>
</array>
```

Apple has included comprehensive documentation on the `ExternalAccessory` framework and how to set it up. For more information see the [Apple Documentation on External Accessory](https://developer.apple.com/library/ios/featuredarticles/ExternalAccessoryPT/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009502)

You will also want to review the included iOS demo application included with this document on GitHub.

## Apple Device Whitelisting
If you are developing an app for use on Apple iOS devices (iPhone, iPad, iPod touch), your app must be whitelisted by Bad Elf prior to submission to TestFlight (External Only) or the iTunes App Store. There is no charge for this whitelisting process.

>⚠️ **WARNING: APPS SUBMITTED TO iTUNES CONNECT FOR TESTFLIGHT (EXTERNAL ONLY) OR APP STORE REVIEW PRIOR TO WHITELISTING APPROVAL WILL BE REJECTED BY APPLE.**

### Whitelisting Process
The process to get your app whitelisted by Bad Elf is relatively easy. At least a week before you are ready to submit your app build to iTunes Connect, please follow these instructions:

1. Complete and submit our [Bad Elf SDK Whitelist Request](http://goo.gl/forms/kuOxVHRXYV) form.
2. Within 24-48 hours you will receive a confirmation email that your information has been received and is being processed by Bad Elf.
3. Within a week we will confirm that your app has been whitelisted and provide you with the necessary information you'll need to include with your app submission to iTunes Connect.
4. You are ready submit your app for review by Apple.


## NMEA Configuration
Bad Elf accessories provide GPS information using industry-standard NMEA protocol. This ASCII-based protocol is easily parsed in any programming language on any computing platform.

When a app opens a Bluetooth SPP or `EASession` connection to a Bad Elf GPS accesory, the accessory will automatically start streaming NMEA sentences with satellite and accuracy info every second (1Hz).  

If your app needs location updates at a faster rate (2-10Hz) or does not want to parse or use the extended satellite/accuracy information in the GSA/GSV sentences, it can send a configuration packet to the accessory.  The changes will take effect within a few seconds, and will persist only for this active connection.

These following binary packets can be sent to Bad Elf GPS accessories to configure the desired reporting rate and verbosity of the NMEA sentences:

#### Simple NMEA Sentences (GGA and RMC only, no satellite info)
| Update Rate | Configuration Packet to Send to Bad Elf Accessory |
|---------------|---------------------------------------------------------|
|1 Hz			   | ```24 be 00 11 05 01 02 05 31 01 32 04 33 01 64 0d 0a```
|2 Hz				| ```24 be 00 11 04 01 02 06 31 02 32 04 33 01 63 0d 0a```
|4 Hz				| ```24 be 00 11 04 01 02 06 31 04 32 04 33 01 61 0d 0a```
|5 Hz				| ```24 be 00 11 06 01 02 04 31 05 32 04 33 01 60 0d 0a```
|10 Hz				| ```24 be 00 11 08 01 02 02 31 0a 32 04 33 01 5b 0d 0a```

#### Extended NMEA Sentences (with GSA and GSV satellite data and DOP values)
| Configuration | Configuration Packet to Send to Bad Elf Accessory |
|---------------|---------------------------------------------------------|
|1 Hz			   | ```24 be 00 11 0b 01 02 ff 31 01 32 04 33 02 63 0d 0a```
|2 Hz				| ```24 be 00 11 10 01 02 fa 31 02 32 04 33 02 62 0d 0a```
|4 Hz				| ```24 be 00 11 12 01 02 f8 31 04 32 04 33 02 60 0d 0a```
|5 Hz				| ```24 be 00 11 13 01 02 f7 31 05 32 04 33 02 5f 0d 0a```
|10 Hz				| ```24 be 00 11 16 01 02 f4 31 0a 32 04 33 02 5a 0d 0a```

## Accessory Metadata
To provide the best user experience possible, apps often need to know the model and version information of the Bad Elf GPS hardware being used.  On iOS, this metadata is available via the `EAAccessory` class.  

For non-iOS Bluetooth clients, we provide the same metadata via a custom `$BADELF` NMEA sentence that is sent when the connection is opened.

The NMEA sentence is in the following format:

```
$PELFID,
<model name>,
<model number>,
<firmware version (AA.BB.CC)>,
<hardware version (AA.BB.CC)>,
<serial number>,
<nickname>
*
<checksum>
```

A sample sentence:

```
$PELFID,Bad Elf GPS Pro,BE-GPS-2200,2.0.87,2.1.0,123456,2200-2.0C-DEV*71
```

An app can also request this information at any time by sending the following binary packet to the accessory:

```
24 be 00 0a 01 00 08 0b 0d 0a
```




## Sample Data
The data returned from the Bad Elf is in NMEA format. Depending on the configuration you pass to the Bad Elf, you should see data returned like the examples below.

##### NMEA Data @ 1Hz (DEFAULT, includes Satelllite Data)
```
$GPGGA,174513.000,3337.4525,N,11154.7255,W,1,4,1.56,439.0,M,-26.1,M,,*6C
$GPGSA,A,	3,15,28,06,26,,,,,,,,,1.81,1.56,0.92*0F
$GPGSV,3,1,11,17,71,219,,28,59,017,16,30,57,121,16,26,43,267,16*75
$GPGSV,	3,2,11,08,41,121,,04,31,142,,01,30,074,,07,26,131,*77
$GPGSV,3,3,11,11,22,053,,15,19,304,22,06,05,181,19*47
$GPRMC,	174513.000,A,3337.4525,N,11154.7255,W,7.82,63.59,070814,,,A*40
```
##### NMEA Data @ 1Hz (No Satellite Data)
```
$GPGGA,174349.000,3337.4138,N,11154.8301,W,1,4,1.58,441.8,M,,M,,*5D
$GPRMC,174349.000,A,3337.4138,N,11154.8301,W,5.14,54.05,070814,,,A*4E
```
##### NMEA Data @ 10Hz (No Satellite Data)
```
$GPGGA,174835.500,3337.3983,N,11154.8672,W,1,4,1.52,429.2,M,,M,,*58
$GPRMC,174835.500,A,3337.3983,N,11154.8672,W,1.20,59.51,070814,,,A*4A
```
##### NMEA Data @ 10Hz (Including Satellite Data)
```
$GPGGA,175012.000,3337.4062,N,11154.8541,W,1,4,1.50,420.4,M,-26.1,M,,*68
$GPGSA,A,3,15,28,06,26,,,,,,,,,1.77,1.50,0.93*01
$GPGSV,3,1,12,17,74,223,13,28,58,021,14,30,55,124,15,26,43,264,29*75
$GPGSV,3,2,12,08,40,123,,04,33,141,,01,30,072,,07,24,132,*71
$GPGSV,3,3,12,11,21,051,,15,20,302,18,06,06,180,32,34,,,*4C
$GPRMC,175012.000,A,3337.4062,N,11154.8541,W,0.94,53.29,070814,,,A*4A
```

## Need Help?
Review the [Wiki](https://github.com/BadElf/gps-sdk/wiki) if you have questions and if you find bugs or need more support, please [submit an issue](https://github.com/BadElf/gps-sdk/issues/new) on GitHub and provide information about your setup.

## License
This project is license under the terms of the BSD-New License. See LICENSE file. 
