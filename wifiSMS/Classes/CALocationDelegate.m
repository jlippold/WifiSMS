
#import "CALocationDelegate.h"
#import "CAPowerManagement.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "localhostAddresses.h"


#define kGPSInterval 1800

@implementation CALocationDelegate

@synthesize locationManager,  _powerManagement;


-(id) init
{
	if (self = [super init])
	{

		
	}
	return self;
}


#pragma mark CAPowerManagementDelegate

-(void) powerWillGoToSleep:(CAPowerManagement *) power
{
	//if(nextTarget == nil)
	//{
		//we have to set it to 1800, this line is here just incase something goes wrong.
		//nextTarget = [[NSDate dateWithTimeIntervalSinceNow:kGPSInterval] retain]; 
	//}
	//[power addPowerUpDate:nextTarget];
}

-(void) powerDidWakeUp:(CAPowerManagement *) power
{


	
}
-(BOOL) powerShouldGoToSleep:(CAPowerManagement *) power
{
	//return !trackingGPS;
	return 0;
}

#pragma mark -


-(void) keepApplicationRunning:(NSTimer *) timer
{
	
}

//this function is to only be called once.
-(void) start
{
	myAppPath = @"/private/var/mobile/Library/WifiSMS/";	
		
	NSString *ppath = [myAppPath stringByAppendingString:@"WebServer.plist"];

	NSMutableDictionary* settingsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:ppath];
	
	NSString *pUserName = @"";
	NSString *pPassword = @"";
	NSString *pPort= @"";
	
	pUserName = [pPassword stringByAppendingString:[settingsDict objectForKey:@"UserName"]];
	pPassword = [pPassword stringByAppendingString:[settingsDict objectForKey:@"Password"]];
	pPort = [pPort stringByAppendingString:[settingsDict objectForKey:@"Port"]];
	
	[settingsDict release];
	
	/* Clear SMS Queue */
	NSString *Spath = [myAppPath stringByAppendingString:@"SMS.plist"];
	NSMutableDictionary *SMSplistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:Spath];
	[SMSplistDict setValue:@"" forKey:@"SMSQueue"];
	[SMSplistDict writeToFile:Spath atomically: YES];
	[SMSplistDict release];
	
	
	wifiUserName = pUserName;
	wifiPassword = pPassword;
	wifiPort = pPort;
	
	NSError *error;
	
	httpServer = [HTTPServer new];
	[httpServer setType:@"_http._tcp."];
	[httpServer setConnectionClass:[MyHTTPConnection class]];
	
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
	[httpServer setDocumentRoot:[NSURL fileURLWithPath:webPath]];
	[localhostAddresses performSelectorInBackground:@selector(list) withObject:nil];	
	
	//Start server	
	[httpServer setPort:[pPort integerValue] ];
	

	
	if(![httpServer start:&error])
	{
		NSLog(@"Error starting HTTP Server: %@", error);
	}
	

	//Clear tmp directory
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WifiSMS/" error:NULL];
	
	
	NSFileManager *fileManager= [NSFileManager defaultManager]; 
	if(![fileManager fileExistsAtPath:@"/tmp/WifiSMS/" isDirectory: YES])
		if(![fileManager createDirectoryAtPath:@"/tmp/WifiSMS/" withIntermediateDirectories:YES attributes:nil error:NULL])
			NSLog(@"Error: Create tmp folder failed /tmp/WifiSMS/");
	
	//Clear Plist data
	NSString *path = [myAppPath stringByAppendingString:@"SMS.plist"];
	NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];	
	[plistDict setValue:@"" forKey:@"Phone"];
	[plistDict setValue:@"" forKey:@"msg"];
	[plistDict setValue:@"" forKey:@"pid"];
	[plistDict setValue:@"" forKey:@"grp"];
	[plistDict setValue:@"" forKey:@"DT"];
	[plistDict setValue:@"" forKey:@"rand"];
	[plistDict setValue:@"" forKey:@"Status"];
	[plistDict setValue:@"" forKey:@"Country"];
	[plistDict writeToFile:path atomically: YES];
	[plistDict release];
	

}



#pragma mark -

-(void) dealloc
{
	[httpServer release];
	//[nextTarget release];
	[_powerManagement release];
	[self.locationManager release];
	[super dealloc];
}



@end
