//
//  CALocationDelegate.h
//  CALocationDemon
//
//  Created by Chris Alvares on 12/30/08.
//  Copyright 2008 Chris Alvares. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import <AddressBook/AddressBook.h>

NSString *wifiUserName;
NSString *wifiPassword;
NSString *wifiPort;
NSString *myAppPath;


@class CAPowerManagement;
@class HTTPServer;

@interface CALocationDelegate : NSObject <CLLocationManagerDelegate>
{
	//BOOL trackingGPS;
	CLLocationManager *locationManager;
	//NSDate *nextTarget;
	CAPowerManagement *_powerManagement;
	HTTPServer *httpServer;
	NSDictionary *addresses;
}

@property (nonatomic, retain) CLLocationManager *locationManager;
//@property(nonatomic, retain) NSDate *nextTarget;
//@property(assign) BOOL trackingGPS;
@property(nonatomic, retain) CAPowerManagement *_powerManagement;


//-(void) keepApplicationRunning:(NSTimer *) timer;
-(void) start;

@end
