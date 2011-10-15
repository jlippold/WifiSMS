#import <UIKit/UIKit.h>
#import "wifiSMSDelegate.h"


int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	wifiSMSDelegate *obj = [[wifiSMSDelegate alloc] init];
	[obj start];
	
	NSDate *now = [[NSDate alloc] init];
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:now
											  interval:5*60
												target:obj
											  selector:@selector(keepApplicationRunning:)
											  userInfo:nil
											   repeats:YES];
	
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
	[runLoop run];
	[timer release];
	
	[pool release];
    return 0;
}
