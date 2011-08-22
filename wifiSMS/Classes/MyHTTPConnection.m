#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "MyHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"
#import <sqlite3.h>
#import "wifiSMSDelegate.h"




extern id CTTelephonyCenterGetDefault();


static void readF(sqlite3_context *context, int argc, sqlite3_value **argv) { return ;}


@implementation MyHTTPConnection

- (NSString *)createBrowseableIndex:(NSString *)path
{
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSMutableString *outdata = [NSMutableString new];
	NSLog(@"Loading index page");
    
	//NSLog(@"outData: %@", outdata);
    [pool drain];
	return [outdata autorelease];
}


- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	if ([@"POST" isEqualToString:method])
	{
		return YES;
	}
	return [super supportsMethod:method atPath:relativePath];
}


- (BOOL)isPasswordProtected:(NSString *)path
{

	if ( ([wifiUserName length] == 0) || ([wifiPassword length] == 0) ) {
		return NO;
	} else {
		if ( [path length] == 1 ) {
			return YES;
		} else {
			return NO;
		}
	}
	
}

- (NSString *)passwordForUser:(NSString *)username
{
		
	if ( [username isEqualToString:wifiUserName] ) {
		return wifiPassword;
	} else {
		return nil;
	}
		
}



- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	if([method isEqualToString:@"POST"] )
	{
		NSString *postStr = nil;	
		CFDataRef postData = CFHTTPMessageCopyBody(request);
		
		if(postData)
		{
			postStr = [[[NSString alloc] initWithData:(NSData *)postData encoding:NSUTF8StringEncoding] autorelease];
			CFRelease(postData);
		}


		// QUERY indivual txt
		if([postStr hasPrefix:@"action=getphone&key=a4a1dda1-166d-47b0-8f31-a8581466da46"] && [path hasPrefix:@"/ajax/"] ) {
			
			int index = [postStr rangeOfString:@"phone="].location + 6;
			NSString *p = [postStr substringFromIndex: index];
			NSData *browseData = [[self QuerySMS:p] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
			
			//NSString *outdata =  [ [QuerySMS alloc] initWithString: @"6464042256" ];

		}
		
		// Download conversation
		if([postStr hasPrefix:@"action=downloadSMS&key=a4a1dda1-166d-47b0-8f31-a8581466da46"] && [path hasPrefix:@"/ajax/"] ) {
			
			int index = [postStr rangeOfString:@"phone="].location + 6;
			NSString *p = [postStr substringFromIndex: index];
			
			[self DownloadSMS:p];
			
			NSString *webPath = @"/tmp/WifiSMS/";
			webPath = [NSString stringWithFormat:@"%@/SMS.csv", webPath];
			return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
			
		}
		
		// Delete conversation
		if([postStr hasPrefix:@"action=deleteSMS&key=a4a1dda1-166d-47b0-8f31-a8581466da46"] && [path hasPrefix:@"/ajax/"] ) {
			
			int index = [postStr rangeOfString:@"grp="].location + 4;
			NSString *p = [postStr substringFromIndex: index];
			NSData *browseData = [[self DeleteSMS:p] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
			
			//NSString *outdata =  [ [QuerySMS alloc] initWithString: @"6464042256" ];
			
		}
		
		// Query totals
		if([postStr hasPrefix:@"action=list&key=a4a1dda1-166d-47b0-8f31-a8581466da46"]  && [path hasPrefix:@"/ajax/"]) {
			
			int index = [postStr rangeOfString:@"CC="].location + 3;
			NSString *CC = [postStr substringFromIndex: index];
			NSData *browseData = [[self QueryTotals:CC] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
			
			//NSData *browseData = [[self QueryTotals] dataUsingEncoding:NSUTF8StringEncoding];
			//return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
					
		}
		
		
		// Check Queue
		if([postStr hasPrefix:@"action=checkQueue&key=a4a1dda1-166d-47b0-8f31-a8581466da46"]  && [path hasPrefix:@"/ajax/"]) {
			
			NSData *browseData = [[self checkQueue] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
		

		
		// settings
		if([postStr hasPrefix:@"action=settings&key=a4a1dda1-166d-47b0-8f31-a8581466da46"]  && [path hasPrefix:@"/ajax/"]) {
			
			int index = [postStr rangeOfString:@"user="].location + 5;
			NSString *newUser = [postStr substringFromIndex: index];
			index = [newUser rangeOfString:@"&"].location;
			newUser = [newUser substringToIndex: index];
			
			index = [postStr rangeOfString:@"pass="].location + 5;
			NSString *newPass = [postStr substringFromIndex: index];
			index = [newPass rangeOfString:@"&"].location;
			newPass = [newPass substringToIndex: index];
			
			index = [postStr rangeOfString:@"port="].location + 5;
			NSString *newPort = [postStr substringFromIndex: index];
			index = [newPort rangeOfString:@"&"].location;
			newPort = [newPort substringToIndex: index];

			NSString *path = [myAppPath stringByAppendingString:@"/WebServer.plist"];
			NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
			
			NSLog(@"User: %@", newUser);
			NSLog(@"Pass: %@", newPass);
			NSLog(@"Port: %@", newPort);
			
			if ([newPort isEqualToString:@"0"]) {
			} else {
				[plistDict setValue:newPort forKey:@"Port"];
			}
			
			if ([newUser isEqualToString:@"fooherp"] && [newPass isEqualToString:@"barderp"]) {
			} else {
				[plistDict setValue:newUser	forKey:@"UserName"];
				[plistDict setValue:newPass forKey:@"Password"];
			}

			[plistDict writeToFile:path atomically: YES];
			[plistDict release];
			
			NSData *response = nil;
			response = [@"Settings saved. Please restart the toggle." dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:response] autorelease];
			
		}
		
		
		// getAllContacts with SMS
		if([postStr hasPrefix:@"action=getContacts&key=a4a1dda1-166d-47b0-8f31-a8581466da46"]  && [path hasPrefix:@"/ajax/"]) {			
			int index = [postStr rangeOfString:@"CC="].location + 3;
			NSString *CC = [postStr substringFromIndex: index];
			NSData *browseData = [[self getAllContacts:CC] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
		
		// getAllContacts
		if([postStr hasPrefix:@"action=LoadFullAddressBook&key=a4a1dda1-166d-47b0-8f31-a8581466da46"]  && [path hasPrefix:@"/ajax/"]) {			
			int index = [postStr rangeOfString:@"CC="].location + 3;
			NSString *CC = [postStr substringFromIndex: index];
			NSData *browseData = [[self LoadFullAddressBook:CC] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		}
		
		
		
		if([postStr isEqualToString:@"action=clearSMS&key=a4a1dda1-166d-47b0-8f31-a8581466da46"] && [path hasPrefix:@"/ajax/"] ) {
			
			NSData *browseData = [[self clearQueue] dataUsingEncoding:NSUTF8StringEncoding];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
						
		}
		
		//SEND SMS
		if([postStr hasPrefix:@"phone="]  && [path hasPrefix:@"/ajax/"] ) {
			
			int index = [postStr rangeOfString:@"&"].location;
			NSString *Phone = [postStr substringToIndex:index];
			Phone = [Phone substringFromIndex:6];
			
			index = [postStr rangeOfString:@"msg="].location + 4;
			NSString *msg = [postStr substringFromIndex: index];
			index = [msg rangeOfString:@"&"].location;
			msg = [msg substringToIndex: index];
			
			index = [postStr rangeOfString:@"pid="].location + 4;
			NSString *pid = [postStr substringFromIndex: index];
			index = [pid rangeOfString:@"&"].location;
			pid = [pid substringToIndex: index];
			
			index = [postStr rangeOfString:@"grp="].location + 4;
			NSString *grp = [postStr substringFromIndex: index];
			index = [grp rangeOfString:@"&"].location;
			grp = [grp substringToIndex: index];
			

			index = [postStr rangeOfString:@"Country="].location + 8;
			NSString *Country = [postStr substringFromIndex: index];
			index = [Country rangeOfString:@"&"].location;
			Country = [Country substringToIndex: index];
						

			msg = [msg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			id ct = CTTelephonyCenterGetDefault();
			void* address = CKSMSAddressCreateWithString(pid); 

			NSLog(@"SMS being Sent"); 
			int group = [grp intValue];			
			
			if (group <= 0) {
					group = CKSMSRecordCreateGroupWithMembers([NSArray arrayWithObject:address]);		
			}
			
			void *msg_to_send = _CKSMSRecordCreateWithGroupAndAssociation(NULL, address, msg, group, 0);	
			CKSMSRecordSend(ct, msg_to_send);
		 
			NSData *response = nil;
			response = [@"SMS Sent!" dataUsingEncoding:NSUTF8StringEncoding];
			
			return [[[HTTPDataResponse alloc] initWithData:response] autorelease];
			
			//Send SMS old
			/*
			

			NSString *DT = @"";
			
			DT = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];			
				
			
			NSString *path = [myAppPath stringByAppendingString:@"SMS.plist"];
			NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
			
			NSString *SMSQueue = @"";
			SMSQueue = [plistDict objectForKey:@"SMSQueue"];
			NSString *toBeQueue = postStr;
			NSData *response = nil;

			if ( [ SMSQueue isEqualToString:@""]) {
				BOOL success = [[CTMessageCenter sharedMessageCenter]  sendSMSWithText:msg serviceCenter:nil toAddress:pid];	
				if (success) {
					[plistDict setValue:toBeQueue forKey:@"SMSQueue"];
					[plistDict writeToFile:path atomically: YES];
					response = [@"SMS in Queue!" dataUsingEncoding:NSUTF8StringEncoding];				
				} else {
					response = [@"Not Sent!" dataUsingEncoding:NSUTF8StringEncoding];
				}
				NSLog(@"Sending SMS: %@ to: %@", msg, pid);
			} else {
				response = [SMSQueue dataUsingEncoding:NSUTF8StringEncoding];
			}
				
			[plistDict release];
			*/
			
			
			
		}
	
	} else {
		if ([path hasPrefix:@"/attachmentPrev:"] || [path hasPrefix:@"/attachmentReal:"]) {
			
			NSMutableString *regName = [NSMutableString new];
			[regName appendString:[path substringFromIndex:16]];
			if ([path hasPrefix:@"/attachmentPrev:"] ) {
				[regName appendString:@"-0-preview"];				
			}

			NSString *attPath = @"/private/var/mobile/Library/SMS/Parts/";
			NSString* file;

			NSArray *dirContents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:attPath error:NULL];
			for ( file in dirContents) {
				
				if ([file hasSuffix: regName])  {
					if ([path hasPrefix:@"/attachmentPrev:"] ) {
						[regName appendString:@".png"];
					}

					NSString *writableDBPath = [@"/tmp/WifiSMS/" stringByAppendingPathComponent:regName ];		

					NSMutableString *oldPath = [NSMutableString new];
					[oldPath appendString:attPath];
					[oldPath appendString:file];

					NSFileManager *filemgr = [NSFileManager defaultManager];
					if ( [filemgr copyItemAtPath:oldPath toPath:writableDBPath error:NULL] == YES) {
						NSLog(@"Copied");
					} else {
						NSLog(@"Not Copied");
						NSLog(file);
						NSLog(writableDBPath);
					}
					
					
					NSString *webPath = @"/tmp/WifiSMS/";
					webPath = [NSString stringWithFormat:@"%@/%@", webPath, regName];

					return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];

				}
				
			}
			
			//return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];

		} else  {
			if ([path hasSuffix:@".png"] || [path hasSuffix:@".ico"] || [path hasSuffix:@".wav"] || [path hasSuffix:@".css"] || [path hasSuffix:@".js"] || [path hasSuffix:@".gif"] || [path hasSuffix:@"oji.html"]){
				NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
				webPath = [NSString stringWithFormat:@"%@/%@", webPath, path];
				return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
				
			} else if ([path hasSuffix:@".jpg"]) {
				
				NSString *webPath = @"/tmp/WifiSMS/";
	
				
				webPath = [NSString stringWithFormat:@"%@/%@", webPath, path];
				NSFileManager *fileManager = [NSFileManager defaultManager];
				if ([fileManager fileExistsAtPath:webPath] ) {
				} else {
					webPath =[myAppPath stringByAppendingString:@"/Web/Contact.jpg"];
				}
				return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
				
			} else {
				//return fake index.html		
				NSString *webPath = [myAppPath stringByAppendingString:@"/Web/index.html"];
				return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
				
			}
		}
		
	
	}
	return [super httpResponseForMethod:method URI:path];
	[pool drain];
}



- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)relativePath
{
	// Inform HTTP server that we expect a body to accompany a POST request
	
	if([method isEqualToString:@"POST"])
		return YES;
	
	return [super expectsRequestBodyFromMethod:method atPath:relativePath];
}

- (void)processDataChunk:(NSData *)postDataChunk
{
	BOOL result = CFHTTPMessageAppendBytes(request, [postDataChunk bytes], [postDataChunk length]);
	
	if(!result)
	{
		NSLog(@"Couldn't append bytes!");
	}
}



- (NSString *)DeleteSMS:(NSString *)grp { 
	NSLog(@"Deleting SMS for group: %@", grp);
	
	BOOL done = NO;
	
	//insert into msg_group
	sqlite3 *database;
	if(sqlite3_open([@"/private/var/mobile/Library/SMS/sms.db" UTF8String], &database) == SQLITE_OK) {
		sqlite3_stmt *newgrp;
		const char *sqlnewgrp = "DELETE FROM msg_group WHERE rowid = ?; DELETE FROM message where group_id = ?; DELETE from group_member where group_id=?  )";
		
		if(sqlite3_prepare_v2(database, sqlnewgrp, -1, &newgrp, NULL) != SQLITE_OK) {
			NSLog(@"Error while deleting: %s", sqlite3_errmsg(database));
		} else {
			sqlite3_bind_text(newgrp, 1, [grp UTF8String], -1, SQLITE_TRANSIENT);
			
			if(SQLITE_DONE != sqlite3_step(newgrp)) {
				NSLog(@"Error while deleting : %s", sqlite3_errmsg(database));
			} else {
				sqlite3_reset(newgrp);
				done = YES;
			}
		}
	}
	
	sqlite3_close(database);
	
	if (done) {
		return @"Deleted";	
	} else {
		return @"Error";			
	}
	
}

- (NSString *)DownloadSMS:(NSString *)phone { 
	
	NSLog(@"generating CSV for group: %@", phone);
		
    NSMutableString *outdata = [[NSMutableString alloc] initWithString:@""];
	NSString *text = @"";
	
	sqlite3 *database;
	if(sqlite3_open([@"/private/var/mobile/Library/SMS/sms.db" UTF8String], &database) == SQLITE_OK) {
		sqlite3_stmt *addStatement;
		const char *sqlStatement2 = "select message.text, message.flags, datetime(message.date, 'unixepoch', 'localtime')  as DT, message.address, message.group_ID, msg_pieces.content_type, msg_pieces.content_loc, msg_pieces.data, msg_pieces.message_id from message left join msg_pieces ON message.rowid=msg_pieces.message_id WHERE ((text is null AND content_type is not null AND content_loc is not null) OR (text is not null)) AND group_id = ? ORDER BY message.rowid asc";
		if(sqlite3_prepare_v2(database, sqlStatement2, -1, &addStatement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(addStatement, 1, [phone UTF8String], -1, SQLITE_TRANSIENT);
			
			[outdata appendString:@"\"Date\",\"From\",\"Message\"\n"];
			while(sqlite3_step(addStatement) == SQLITE_ROW) {
				
				char *text1 = (char *)sqlite3_column_text(addStatement, 0);
				if (text1 !=nil) {
					text = [NSString stringWithUTF8String: text1];
					NSString *flags = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 1)];
					NSString *textdate = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 2)];
					NSString *p = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 3)];
					
					text = [text stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
					
					[outdata appendString:@"\""];
					[outdata appendString: textdate];
					[outdata appendString:@"\","];

					[outdata appendString:@"\""];
					if ( [flags isEqualToString:@"2"]  || [flags isEqualToString:@"0"]) {
						[outdata appendString:p];
					} else {
						[outdata appendString:@"Me"];
					}
					[outdata appendString:@"\","];
					
					[outdata appendString:@"\""];
					[outdata appendString:text];
					[outdata appendString:@"\"\n"];


				} 
				text1 = nil;
			}
		}
		sqlite3_finalize(addStatement);
		
	}
	
	sqlite3_close(database);
	
	
	
	NSString *filename = [@"/tmp/WifiSMS/" stringByAppendingString: @"SMS.csv"];
	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
	[outdata writeToFile:filename atomically:YES encoding: NSUTF8StringEncoding error: NULL];
	[outdata release];
	
	return 0;
}


- (NSString *)QuerySMS:(NSString *)phone { 
	NSLog(@"Getting SMS for group: %@", phone);
	
	/*
	 SMS Shit I found out
	 ====================================================================================================
	 message.rowid = 23790
	 message.groupid = 413
	 
	 msg_pieces.message_id = 23790
	 msg_pieces.content_id = 1
	 msg_pieces.content_loc = IMG_0541.jpg
	 msg_pieces.content_type = image/jpeg
	 
	 if content_type = text/plain then
	 msg_pieces.data = X'53686520676F74206F7574' which converts from hex to text is actual message
	 
	 Always do where content_type && content_loc != NULL
	 
	 /private/var/mobile/Library/SMS/Parts/9d/14/23790-0.jpg
	 /private/var/mobile/Library/SMS/Parts/9d/14/23790-0-preview == skinned bubble preview
	 
	 ======================================================================================================
	 SELECT  * FROM    (
	 
	 select message.text, message.flags, datetime(message.date, 'unixepoch', 'localtime') as DT, message.address, message.group_ID, msg_pieces.content_type, msg_pieces.content_loc, msg_pieces.data, msg_pieces.message_id
	 from message left join msg_pieces ON message.rowid=msg_pieces.message_id
	 
	 WHERE 
	 ((text is null AND content_type is not null and content_loc is not null) OR (text is not null))
	 and 
	 CASE WHEN 
	 substr(replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') ,1,1) = '1' 
	 THEN substr(replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') ,2) 
	 ELSE replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') 
	 END = ?
	 
	 ORDER BY date desc limit 100
	 
	 ) Order by DT ASC
	 ======================================================================================================
	 
	 */
	
    NSMutableString *outdata = [[NSMutableString alloc] initWithString:@""];
	NSString *text = @"";
	
	sqlite3 *database;
	if(sqlite3_open([@"/private/var/mobile/Library/SMS/sms.db" UTF8String], &database) == SQLITE_OK) {
		sqlite3_stmt *addStatement;
		const char *sqlStatement2 = "SELECT * FROM ( select message.text, message.flags, message.date as DT, message.address, message.group_ID, msg_pieces.content_type, msg_pieces.content_loc, msg_pieces.data, msg_pieces.message_id from message left join msg_pieces ON message.rowid=msg_pieces.message_id WHERE ((text is null AND content_type is not null AND content_loc is not null) OR (text is not null)) AND group_id = ? ORDER BY message.rowid desc limit 100) Order by DT ASC";
		if(sqlite3_prepare_v2(database, sqlStatement2, -1, &addStatement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(addStatement, 1, [phone UTF8String], -1, SQLITE_TRANSIENT);
			[outdata appendString:@"||-||"];
			while(sqlite3_step(addStatement) == SQLITE_ROW) {

				char *text1 = (char *)sqlite3_column_text(addStatement, 0);
				if (text1 !=nil) {
					text = [NSString stringWithUTF8String: text1];
					NSString *flags = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 1)];
					NSString *textdate = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 2)];
					NSString *p = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 3)];
					NSString *grp = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 4)];
					[outdata appendString: textdate];
					[outdata appendString:@"||?||"];
					[outdata appendString: text ];
					[outdata appendString:@"||?||"];
					[outdata appendString:flags];						
					[outdata appendString:@"||?||"];
					[outdata appendString:grp];
					[outdata appendString:@"||?||"];
					[outdata appendString:p];
					[outdata appendString:@"||-||"];
				} else { 
					/*
					char *content_type = (char *)sqlite3_column_text(addStatement, 5);
					char *content_loc = (char *)sqlite3_column_text(addStatement, 6);
					char *hexdata = (char *)sqlite3_column_text(addStatement, 7);
					char *message_id = (char *)sqlite3_column_text(addStatement, 8);
					*/
					
					
					
					NSString *flags = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 1)];
					NSString *textdate = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 2)];
					NSString *p = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 3)];
					NSString *grp = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 4)];
					
					NSString *content_type = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 5)];
					NSString *content_loc = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 6)];
					NSString *hexdata = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 7)];
					NSString *message_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 8)];
					
					//text = [NSString stringWithUTF8String: message_id];
					[outdata appendString: textdate];
					[outdata appendString:@"||?||attachment:"];
					[outdata appendString: message_id ];
					
						[outdata appendString: @"||" ];
						[outdata appendString: content_type ];
						[outdata appendString: @"||" ];
						[outdata appendString: hexdata ];
						[outdata appendString: @"||" ];
						[outdata appendString: content_loc ];
					
					[outdata appendString:@"||?||"];
					[outdata appendString:flags];						
					[outdata appendString:@"||?||"];
					[outdata appendString:grp];
					[outdata appendString:@"||?||"];
					[outdata appendString:p];
					[outdata appendString:@"||-||"];
				}
				text1 = nil;
				

			}
		}
		sqlite3_finalize(addStatement);
		
		

		/*This was to mark as read, but although the DB tables are marked as read with this call, other SMS apps were acting screwy */
		/*there's prolly a hook we have to call to let other SMS apps know it was read... I dunno how to hook it properly */
		
		/*
		NSLog(@"Marking messages as read");
		sqlite3_stmt *updateStatement;
		const char *fn_name = "read"; 
		sqlite3_create_function(database, fn_name, 1, SQLITE_INTEGER, nil, readF, nil, nil); 
		const char *sql3 = "UPDATE message SET read = '1' WHERE group_id = ?";
		
		if(sqlite3_prepare_v2(database, sql3, -1, &updateStatement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(updateStatement, 1, [phone UTF8String], -1, SQLITE_TRANSIENT);	
			if(SQLITE_DONE != sqlite3_step(updateStatement)) {
				NSLog(@"Error while marking message as read1: %s", sqlite3_errmsg(database));
				sqlite3_reset(updateStatement);
			}  else {
				sqlite3_finalize(updateStatement);
				NSLog(@"Marked message as read");
			}		
		} else {
			NSLog(@"Error while marking as read: %s", sqlite3_errmsg(database));
		}
		
		NSLog(@"Marking group as read");
		
		sqlite3_stmt *updategrpStatement;
		
		const char *sql4 = "UPDATE msg_group SET unread_count = 0 where ROWID = ?";
		if(sqlite3_prepare_v2(database, sql4, -1, &updategrpStatement, NULL) == SQLITE_OK) {
			sqlite3_bind_text(updategrpStatement, 1, [phone UTF8String], -1, SQLITE_TRANSIENT);	
			if(SQLITE_DONE != sqlite3_step(updategrpStatement)) {
				NSLog(@"Error while marking group message as read1: %s", sqlite3_errmsg(database));
				sqlite3_reset(updategrpStatement);
			}  else {
				sqlite3_finalize(updategrpStatement);
				NSLog(@"Marked group message as read");
			}		
		} else {
			NSLog(@"Error while marking as read: %s", sqlite3_errmsg(database));
		}
		 */
		
		
	}
	
	sqlite3_close(database);
	return [outdata autorelease];
}


-(NSString *)LoadFullAddressBook:(NSString *)CC { 
	
	
	NSMutableString *outdata = [[NSMutableString alloc] initWithString:@"{\"AddressBook\" : [ { \"Name\" : \"Foobar\",  \"Phone\" : \"Foobar\", \"CleanedPhone\" : \"Foobar\"} "];
	
	ABAddressBookRef addressBook = ABAddressBookCreate( );
	CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
	CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
	
	for( int i = 0 ; i < nPeople ; i++ )
	{
		ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i );
		ABMultiValueRef name1 =(NSString*)ABRecordCopyValue(ref,kABPersonPhoneProperty);
		
		NSString *firstName = (NSString *)ABRecordCopyValue(ref, kABPersonFirstNameProperty);
		NSString *lastName = (NSString *)ABRecordCopyValue(ref, kABPersonLastNameProperty);
		
		if (lastName == nil) {
			lastName = @"";
		}
		if (firstName == nil) {
			firstName = @"";
		}
		
		NSString *contactFirstLast = [NSString stringWithFormat:@"%@ %@",firstName, lastName];
		contactFirstLast = [self JSONSafe:contactFirstLast];
		
		NSString *phoneNoFormat = @"";
		NSString* mobile=@"";
		
		
		for(CFIndex i=0;i<ABMultiValueGetCount(name1);i++)
		{
			
			mobile=(NSString*)ABMultiValueCopyValueAtIndex(name1,i);
			
			phoneNoFormat = [[mobile componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
			
			if ([phoneNoFormat hasPrefix:@"0"]){
				phoneNoFormat = [phoneNoFormat substringFromIndex:1];
			}
			
			if ([phoneNoFormat hasPrefix:CC]){
				phoneNoFormat = [phoneNoFormat substringFromIndex:[CC length]];
			}
			
			mobile = [self JSONSafe:mobile];
			
			if ([phoneNoFormat length] > 1) {
				[outdata appendString:[NSString stringWithFormat:@", { \"Name\" : \"%@\", ", contactFirstLast]];
				[outdata appendString:[NSString stringWithFormat:@"\"Phone\" : \"%@\", ", mobile]];
				[outdata appendString:[NSString stringWithFormat:@"\"CleanedPhone\" : \"%@\" } ", phoneNoFormat]];
			}
		}
		
	}
	
	[outdata appendString:@" ]} "];
	
	return [outdata autorelease];
}

-(NSString *)getAllContacts:(NSString *)CC { 

	NSLog(@"get All Contacts Country Code %@", CC);
	
	NSMutableString *outdata = [[NSMutableString alloc] initWithString:@"{\"AddressBook\" : [ { \"Foo\" : \"Bar\" } "];
	
	ABAddressBookRef addressBook = ABAddressBookCreate( );
	CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
	CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
	
	for( int i = 0 ; i < nPeople ; i++ )
	{
		ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i );
		ABMultiValueRef name1 =(NSString*)ABRecordCopyValue(ref,kABPersonPhoneProperty);
		
		NSString *firstName = (NSString *)ABRecordCopyValue(ref, kABPersonFirstNameProperty);
		NSString *lastName = (NSString *)ABRecordCopyValue(ref, kABPersonLastNameProperty);
		
		if (lastName == nil) {
			lastName = @"";
		}
		if (firstName == nil) {
			firstName = @"";
		}
		
		NSString *contactFirstLast = [NSString stringWithFormat:@"%@ %@",firstName, lastName];
		contactFirstLast = [self JSONSafe:contactFirstLast];
		
		NSString *phoneNoFormat = @"";
		NSString* mobile=@"";
		
		
		for(CFIndex i=0;i<ABMultiValueGetCount(name1);i++)
		{
			
			mobile=(NSString*)ABMultiValueCopyValueAtIndex(name1,i);
	
			phoneNoFormat = [[mobile componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
			
			if ([phoneNoFormat hasPrefix:@"0"]){
				phoneNoFormat = [phoneNoFormat substringFromIndex:1];
			}
			if ([phoneNoFormat hasPrefix:CC]){
				phoneNoFormat = [phoneNoFormat substringFromIndex:[CC length]];
			}
			

			
			
			if ([phoneNoFormat length] > 1) {
				[outdata appendString:[NSString stringWithFormat:@", { \"%@\" : \"%@\" } ", phoneNoFormat, contactFirstLast]];
				//UIImage* image;
				//Copy Images
				if(ABPersonHasImageData(ref)){
					
					NSData* imageData = (NSData*)ABPersonCopyImageData(ref);
					UIImage* image = [UIImage imageWithData:imageData];
					[imageData release];
					CGRect sz = CGRectMake(0.0f, 0.0f, 96.0f, 96.0f);
					UIImage *smallImage = resizedImage(image, sz);
					NSData *imageDataNew = [NSData dataWithData:UIImageJPEGRepresentation(smallImage, 1)];
					NSString *fName = [phoneNoFormat stringByAppendingString:@".jpg"];
					NSString *writableDBPath = [@"/tmp/WifiSMS/" stringByAppendingPathComponent:fName];		
					[imageDataNew writeToFile:writableDBPath atomically:NO];
					//[imageDataNew release];
					/*
					image = [UIImage imageWithData:(NSData *)ABPersonCopyImageData(ref)];
					NSData *imageData = [NSData dataWithData:UIImageJPEGRepresentation(image, 1)];
					NSString *fName = [phoneNoFormat stringByAppendingString:@".jpg"];
					NSString *writableDBPath = [@"/private/var/mobile/Documents/treasonSMS/" stringByAppendingPathComponent:fName];				
					[imageData writeToFile:writableDBPath atomically:NO];
					 */
				}
			}
		}
		
	}
	
	[outdata appendString:@" ], \"WithSMS\" : [ { \"Bar\" : \"Foo\" } "];
	
	sqlite3 *database;
	if(sqlite3_open([@"/private/var/mobile/Library/SMS/sms.db" UTF8String], &database) == SQLITE_OK) {
		
		const char *sqlStatement2 = "select Max(address) as phone, Max(date)  as DT, max(group_id) as grp from message inner join msg_group ON message.group_id=msg_group.ROWID where msg_group.Type = 0 AND Address is not null GROUP BY address order by date DESC";		
		//const char *sqlStatement2 = "select address as phone, Max(date)  as DT, max(group_id) as grp from message WHERE Address is not null GROUP BY address order by date DESC";
		//const char *sqlStatement2 = "select CASE WHEN substr(replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') ,1,1) = '1' THEN substr(replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') ,2) ELSE replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') END as phone, Max(date)  as DT, max(group_id) as grp from message WHERE Address is not null GROUP BY address order by date DESC";
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(database, sqlStatement2, -1, &compiledStatement, NULL) == SQLITE_OK) {
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				NSString *phoneNoFormat = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 0)];		
				NSString *DT = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 1)];	
				NSString *grp = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 2)];	
				
				phoneNoFormat = [[phoneNoFormat componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
				
				if ([phoneNoFormat hasPrefix:@"0"]){
					phoneNoFormat = [phoneNoFormat substringFromIndex:1];
				}
				if ([phoneNoFormat hasPrefix:CC]){
					phoneNoFormat = [phoneNoFormat substringFromIndex:[CC length]];
				}
			
				
				[outdata appendString:[NSString stringWithFormat:@", { \"%@\" : \"%@||?||%@\" } ", phoneNoFormat, DT, grp]];
			}
		}
		sqlite3_finalize(compiledStatement);
	}
	sqlite3_close(database);
	
	[outdata appendString:@" ]} "];
	
	return [outdata autorelease];
}

- (NSString *) QueryTotals: (NSString *)CC { 
	//NSLog(@"Refresh called");
	NSMutableString *outdata = [[NSMutableString alloc] initWithString:@""];
	sqlite3 *database;
	
	[outdata appendString:@"{\"messages\" :[ {\"foo\": \"bar\"}"];
	
	if(sqlite3_open([@"/private/var/mobile/Library/SMS/sms.db" UTF8String], &database) == SQLITE_OK) {
		const char *sqlStatement2 = "SELECT * FROM (select Max(message.ROWID) as rowID, group_id, address, text, CASE WHEN flags = 3 THEN 'fromMe' ELSE 'toMe' END as flags from message inner join msg_group ON message.group_id=msg_group.ROWID where msg_group.Type = 0 AND Address is not null GROUP BY message.group_id ) tmp GROUP BY group_id ORDER BY rowID DESC";
		//const char *sqlStatement2 = "select CASE WHEN substr(replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') ,1,1) = '1' THEN substr(replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') ,2) ELSE replace(replace(replace(replace(replace(address,')',''),'(',''),' ',''),'-',''),'+','') END as phone, count(ROWID) from message WHERE Address is not null Group BY Address";
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(database, sqlStatement2, -1, &compiledStatement, NULL) == SQLITE_OK) {
						
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				NSString *rowID = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 0)];
				NSString *grpID = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 1)];
				NSString *phoneNoFormat = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 2)];
				NSString *message = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 3)];
				NSString *from = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(compiledStatement, 4)];
				
				phoneNoFormat = [[phoneNoFormat componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
				
				if ([phoneNoFormat hasPrefix:CC]){
					phoneNoFormat = [phoneNoFormat substringFromIndex:[CC length]];
				}
				
				//if ([phoneNoFormat hasPrefix:@"0"]){
				//	phoneNoFormat = [phoneNoFormat substringFromIndex:1];
				//}
				
				rowID = [self JSONSafe:rowID];
				grpID = [self JSONSafe:grpID];
				message = [self JSONSafe:message];
				from = [self JSONSafe:from];
				
				[outdata appendString:[NSString stringWithFormat:@",{\"lastMessageID\":\"%@\",\"group\":\"%@\", \"Phone\":\"%@\", \"Text\":\"%@\", \"flags\": \"%@\"}", rowID, grpID, phoneNoFormat, message, from]];	

			}
		}
		sqlite3_finalize(compiledStatement);
	}
	sqlite3_close(database);

	[outdata appendString:@"]}"];
	return [outdata autorelease];
}
								   
-(NSString *)JSONSafe:(NSString *)string
{
 string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
 string = [string stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
 string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"&#92;"];
 string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
 string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@""];
 string = [string stringByReplacingOccurrencesOfString:@"\b" withString:@""];
 string = [string stringByReplacingOccurrencesOfString:@"\f" withString:@""];
 string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
 string = [string stringByReplacingOccurrencesOfString:@"\v" withString:@" "];
 string = [string stringByReplacingOccurrencesOfString:@"\v" withString:@""];
 return string;
}				   


- (NSString *) checkQueue {
	NSMutableString *outdata = [[NSMutableString alloc] initWithString:@""];

	NSString *path = [myAppPath stringByAppendingString:@"SMS.plist"];
	
	NSMutableDictionary* plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	NSString *rand = @"";
	NSString *stat= @"";
	
	rand = [plistDict objectForKey:@"rand"];
	stat = [plistDict objectForKey:@"Status"];
	
	if ([stat isEqualToString:@"Sent"]) {
		[outdata appendString:rand];
		[plistDict setValue:@"" forKey:@"Phone"];
		[plistDict setValue:@"" forKey:@"msg"];
		[plistDict setValue:@"" forKey:@"pid"];
		[plistDict setValue:@"" forKey:@"grp"];
		[plistDict setValue:@"" forKey:@"DT"];
		[plistDict setValue:@"" forKey:@"rand"];
		[plistDict setValue:@"" forKey:@"Country"];
		[plistDict setValue:@"" forKey:@"Status"];
		[plistDict writeToFile:path atomically: YES];
	} else {
		[outdata appendString:@"Waiting"];
	}
	
	[plistDict release];
	
	return [outdata autorelease];
}

- (NSString *) clearQueue {
	NSMutableString *outdata = [[NSMutableString alloc] initWithString:@""];
	NSString *path = [myAppPath stringByAppendingString:@"SMS.plist"];

	NSMutableDictionary* plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];

		[plistDict setValue:@"" forKey:@"Phone"];
		[plistDict setValue:@"" forKey:@"msg"];
		[plistDict setValue:@"" forKey:@"pid"];
		[plistDict setValue:@"" forKey:@"grp"];
		[plistDict setValue:@"" forKey:@"DT"];
		[plistDict setValue:@"" forKey:@"rand"];
		[plistDict setValue:@"" forKey:@"Country"];
		[plistDict setValue:@"" forKey:@"Status"];
		[plistDict writeToFile:path atomically: YES];	
	
	[plistDict release];
	[outdata appendString:@"Deleted"];
	

	return [outdata autorelease];
}

	
resizedImage (UIImage *inImage, CGRect thumbRect) {
	CGImageRef			imageRef = [inImage CGImage];
	CGImageAlphaInfo	alphaInfo = CGImageGetAlphaInfo(imageRef);
	
	// There's a wierdness with kCGImageAlphaNone and CGBitmapContextCreate
	// see Supported Pixel Formats in the Quartz 2D Programming Guide
	// Creating a Bitmap Graphics Context section
	// only RGB 8 bit images with alpha of kCGImageAlphaNoneSkipFirst, kCGImageAlphaNoneSkipLast, kCGImageAlphaPremultipliedFirst,
	// and kCGImageAlphaPremultipliedLast, with a few other oddball image kinds are supported
	// The images on input here are likely to be png or jpeg files
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
	
	// Build a bitmap context that's the size of the thumbRect
	CGContextRef bitmap = CGBitmapContextCreate(
												NULL,
												thumbRect.size.width,		// width
												thumbRect.size.height,		// height
												CGImageGetBitsPerComponent(imageRef),	// really needs to always be 8
												4 * thumbRect.size.width,	// rowbytes
												CGImageGetColorSpace(imageRef),
												alphaInfo
												);
	
	// Draw into the context, this scales the image
	CGContextDrawImage(bitmap, thumbRect, imageRef);
	
	// Get an image from the context and a UIImage
	CGImageRef	ref = CGBitmapContextCreateImage(bitmap);
	UIImage*	result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);	// ok if NULL
	CGImageRelease(ref);
	
	return result;
}

@end