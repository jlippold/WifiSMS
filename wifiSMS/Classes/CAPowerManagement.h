//
//  CAPowerManagement.h
//  Alarm
//
//  Created by Chris Alvares on 5/30/09.
//  Copyright 2009 Chris Alvares. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import <AddressBook/AddressBook.h>

@interface CAPowerManagement : NSObject
{
	io_connect_t root_port;
	io_object_t notifier;
	id delegate;
}

@property(retain) id delegate;

-(void)powerMessageReceived:(natural_t)messageType withArgument:(void *) messageArgument;
-(void) addPowerUpDate:(NSDate *) date;

@end

@interface NSObject(CAPowerManagementDelegate)
-(void) powerWillGoToSleep:(CAPowerManagement *) power;
-(void) powerDidWakeUp:(CAPowerManagement *) power;
-(BOOL) powerShouldGoToSleep:(CAPowerManagement *) power;
@end