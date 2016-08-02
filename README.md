<h3 align="center">
  <img src="assets/img/sdk-logo.png" alt="bad-elf-sdk-logo" />
</h3>

# Bad Elf GPS SDK
=================

[![Twitter: @bad_elf](https://img.shields.io/badge/contact-@bad__elf-blue.svg?style=flat)](https://twitter.com/bad_elf)
![](https://img.shields.io/badge/license-BSD--New-green.svg)
![](https://img.shields.io/badge/version-v1.0.0-blue.svg)

Bad Elf is excited to provide developers with the protocol information and sample code to communicate with Bad Elf GPS accessories across many platforms. This SDK provides real-time and native support for the wide range of data and configurations that each Bad Elf GPS accessory supports.

We understand that applications have unique requirements and we have made every effort to ensure that our protocol is as lightweight and stable as possible. 

We strongly suggest developers review all the information contained here before starting to integrate the protocol or sample code into your application.

## Bad Elf Protocol Features
              |  Bad Elf
--------------|------------------------------------------------------------
:rocket: 	  | Fast and reliable positional data updates in binary or NMEA format
:wrench:   | Access extended satellite and accuracy information not available elsewhere
:computer: | Support for iOS, Android, Windows, and any other platform via Bluetooth SPP
:book:     | No binary SDK to integrate into your app
:pencil2:  | Properly formatted raw NMEA sentences
:octocat:  | Frequent spec updates and rapid support responses


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
| Bad Elf GPS for 30-pin    | BE-GPS-1000 | v1.3.14 | iOS only via EA    | 
| Bad Elf GPS for Lightning | BE-GPS-1008 | v1.0.18 | iOS only via EA    |
| Bad Elf GPS Pro | BE-GPS-2200 | v2.0.80 | Bluetooth         |
| Bad Elf GPS Pro+ | BE-GPS-2300 | v2.1.36 | Bluetooth, USB         |
| Bad Elf GNSS Surveyor | BE-GPS-3300 | v2.1.36 | Bluetooth, USB         |


> If your app detects a Bad Elf GPS accessory with older firmware, you should prompt the user to perform a firmware update using the official [Bad Elf GPS App (iOS only)](https://itunes.apple.com/us/app/bad-elf-gps/id391764718?mt=8&uo=4&at=10I4Go). For non-iOS apps and users, you can point them to our [instructions for upgrading Bad Elf GPS accessories via USB](#).  This only applies to the accessories with USB connectivity as shown above.

## Apple Device Whitelisting
If you are developing an app for use on Apple iOS devices (iPhone, iPad, iPod touch), your app must be whitelisted by Bad Elf prior to submission to TestFlight (External Only) or the iTunes App Store. There is no charge for this whitelisting process.

>⚠️ **WARNING: APPS SUBMITTED TO iTUNES CONNECT FOR TESTFLIGHT (EXTERNAL ONLY) OR APP STORE REVIEW PRIOR TO WHITELISTING APPROVAL WILL BE REJECTED BY APPLE.**

### Whitelisting Process
The process to get your app whitelisted by Bad Elf is relatively easy. At least a week before you are ready to submit your app build to iTunes Connect, please follow these instructions:

1. Complete and submit our [Bad Elf SDK Whitelist Request](http://goo.gl/forms/kuOxVHRXYV) form.
2. Within 24-48 hours you will receive a confirmation email that your information has been received and is being processed by Bad Elf.
3. Within a week we will confirm that your app has been whitelisted and provide you with the necessary information you'll need to include with your app submission to iTunes Connect.
4. You are ready submit your app for review by Apple.

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

## Packet Configuration
If your app needs to supply users with the most accurate GPS information, the Bad Elf hardware is a great choice. Bad Elf has built the following protocol definition to allow developers to request the raw NMEA data from the Bad Elf hardware, however, it is up to the app developer to choose how to parse, use, and display this NMEA data.

If a Bad Elf GPS is connected to an app and does not recieve a configuration packet with 3-5 seconds, the accessory automatically starts streaming NMEA sentences at 1Hz with satellite data. An app can send one or more configuration packets at any time after the session has been opened.

The following configuration data values are available to developers:
#### NMEA Sentences (without GSA and GSV satellite data)
| Configuration | Packet Data |
|---------------|---------------------------------------------------------|
|1 Hz			   | ```24 be 00 11 05 01 02 05 31 01 32 04 33 01 64 0d 0a```
|2 Hz				| ```24 be 00 11 04 01 02 06 31 02 32 04 33 01 63 0d 0a```
|4 Hz				| ```24 be 00 11 07 01 02 03 31 04 32 11 33 01 54 0d 0a```
|5 Hz				| ```24 be 00 11 06 01 02 04 31 05 32 04 33 01 60 0d 0a```
|10 Hz				| ```24 be 00 11 08 01 02 02 31 0a 32 04 33 01 5b 0d 0a```

#### NMEA Sentences (including GSA and GSV satellite data and DOP values)
| Configuration | Packet Data |
|---------------|---------------------------------------------------------|
|1 Hz			   | ```24 be 00 11 0b 01 02 ff 31 01 32 04 33 02 63 0d 0a```
|2 Hz				| ```24 be 00 11 10 01 02 fa 31 02 32 04 33 02 62 0d 0a```
|4 Hz				| ```24 be 00 11 12 01 02 f8 31 04 32 04 33 02 60 0d 0a```
|5 Hz				| ```24 be 00 11 13 01 02 f7 31 05 32 04 33 02 5f 0d 0a```
|10 Hz				| ```24 be 00 11 16 01 02 f4 31 0a 32 04 33 02 5a 0d 0a```

## Sample Data
The data returned from the Bad Elf is in NMEA format. Depending on the configuration you pass to the Bad Elf, you should see data returned like the examples below.

##### NMEA Data @ 1Hz (No Satellite Data)
```
$GPGGA,174349.000,3337.4138,N,11154.8301,W,1,4,1.58,441.8,M,,M,,*5D
$GPRMC,174349.000,A,3337.4138,N,11154.8301,W,5.14,54.05,070814,,,A*4E
```
##### NMEA Data @ 1Hz (Including Satelllite Data)
```
$GPGGA,174513.000,3337.4525,N,11154.7255,W,1,4,1.56,439.0,M,-26.1,M,,*6C
$GPGSA,A,	3,15,28,06,26,,,,,,,,,1.81,1.56,0.92*0F
$GPGSV,3,1,11,17,71,219,,28,59,017,16,30,57,121,16,26,43,267,16*75
$GPGSV,	3,2,11,08,41,121,,04,31,142,,01,30,074,,07,26,131,*77
$GPGSV,3,3,11,11,22,053,,15,19,304,22,06,05,181,19*47
$GPRMC,	174513.000,A,3337.4525,N,11154.7255,W,7.82,63.59,070814,,,A*40
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
