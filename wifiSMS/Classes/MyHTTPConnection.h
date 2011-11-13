#import <Foundation/Foundation.h>
#import "HTTPConnection.h"
#import <sqlite3.h>
#import <AddressBook/AddressBook.h>


@interface MyHTTPConnection : HTTPConnection
{
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;

}

//- (BOOL)isBrowseable:(NSString *)path;
- (NSString *)createBrowseableIndex:(NSString *)path;

//- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength;
- (NSString *)QuerySMS:(NSString *)postStr;
- (NSString *)DeleteSMS:(NSString *)grp;
- (NSString *)QueryTotals:(NSString *)CC;
- (NSString *)checkQueue;
- (NSString *)clearQueue;

- (NSString *)getAllContacts:(NSString *)CC;
- (NSString *)LoadFullAddressBook:(NSString *)CC;
- (NSString *)JSONSafe:(NSString *)string;

- (BOOL)isPasswordProtected:(NSString *)path;
- (NSString *)passwordForUser:(NSString *)username;

@end