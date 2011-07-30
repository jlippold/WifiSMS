//
//  CAPowerManagement.m
//  Alarm
//
//  Created by Chris Alvares on 5/30/09.
//  Copyright 2009 Chris Alvares. All rights reserved.
//

#import "CAPowerManagement.h"


@implementation CAPowerManagement

extern void * CPSchedulePowerUpAtDate (CFDateRef);

@synthesize delegate;

//is function is called whenever any power is given, found through the insomnia source code http://code.google.com/p/iphone-insomnia/
void powerCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{	
	//[(CAPowerManagement *)refCon powerMessageReceived: messageType withArgument: messageArgument];
}


-(id) init
{
	if (self = [super init])
	{
		//IONotificationPortRef notificationPort;
		//root_port = IORegisterForSystemPower(self, &notificationPort, powerCallback, &notifier);
		
		// add the notification port to the application runloop
		//CFRunLoopAddSource(CFRunLoopGetCurrent(),IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopCommonModes );
	}
	return self;
}

//this code is from the insomnia source code http://code.google.com/p/iphone-insomnia/
- (void)powerMessageReceived:(natural_t)messageType withArgument:(void *) messageArgument
{
	/*
    switch (messageType)
    {
        case kIOMessageSystemWillSleep:

			if(self.delegate && [self.delegate respondsToSelector:@selector(powerWillGoToSleep:)])
			{
				[self.delegate powerWillGoToSleep:self];
			}
            IOAllowPowerChange(root_port, (long)messageArgument);  
            break;
        case kIOMessageCanSystemSleep:

			
			//NSLog(@"powerMessageReceived kIOMessageCanSystemSleep");
			NSLog(@"");
			BOOL shouldSleep = YES;
			if(self.delegate && [self.delegate respondsToSelector:@selector(powerShouldGoToSleep:)])
			{
				shouldSleep = [self.delegate powerShouldGoToSleep:self];
			} else break;
			
			if(!shouldSleep)
			{
				//NSLog(@"Stopping phone from going to sleep");
				IOCancelPowerChange(root_port, (long)messageArgument);
			}
			else
			{
				//NSLog(@"We are not on the alarm, letting go to sleep");
				IOAllowPowerChange(root_port, (long)messageArgument);	
			}
			
            break; 
        case kIOMessageSystemHasPoweredOn:
            //NSLog(@"powerMessageReceived kIOMessageSystemHasPoweredOn");
			if(self.delegate && [self.delegate respondsToSelector:@selector(powerWillGoToSleep:)])
			{
				[self.delegate powerDidWakeUp:self];
			}
            break;
    }

*/
}

-(void) addPowerUpDate:(NSDate *) date
{
	//CPSchedulePowerUpAtDate((CFDateRef)date);
}

-(void) dealloc
{
	delegate = nil;
	[super dealloc];
}

@end
