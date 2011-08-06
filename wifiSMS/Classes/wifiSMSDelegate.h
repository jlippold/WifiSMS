#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NSString *wifiUserName;
NSString *wifiPassword;
NSString *wifiPort;
NSString *myAppPath;


@class HTTPServer;

@interface wifiSMSDelegate : NSObject <UIApplicationDelegate>
{
	HTTPServer *httpServer;
	NSDictionary *addresses;
}



//-(void) keepApplicationRunning:(NSTimer *) timer;
-(void) start;

@end
