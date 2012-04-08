#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>



#import "MyHTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "AsyncSocket.h"
#import <sqlite3.h>
#import "wifiSMSDelegate.h"

#import <ChatKit.framework/CKSMSService.h>
#import <ChatKit.framework/CKSMSMessage.h>
#import <ChatKit.framework/CKSMSEntity.h>

#import <ChatKit.framework/CKMadridService.h>
#import <ChatKit.framework/CKMadridMessage.h>
#import <ChatKit.framework/CKMadridEntity.h>

#import <ChatKit.framework/CKEntity.h>
#import <ChatKit.framework/CKService.h> 
#import <ChatKit.framework/CKPreferredServiceManager.h> 
#import <ChatKit.framework/CKClientComposeService.h> 

#import <ChatKit.framework/CKConversation.h>
#import <ChatKit.framework/CKConversationList.h>
#import <ChatKit.framework/CKMessage.h>
#import <ChatKit.framework/CKMessagePart.h>


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


- (BOOL)isSecureServer
{
	// Override me to create an https server...
	
	return NO;
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
			

            
            NSData *browseData = [[self QuerySMS:postStr] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
            
		}
		
		// Download conversation
		if([postStr hasPrefix:@"action=downloadSMS&key=a4a1dda1-166d-47b0-8f31-a8581466da46"] && [path hasPrefix:@"/ajax/"] ) {
			
			int index = [postStr rangeOfString:@"phone="].location + 6;
			NSString *p = [postStr substringFromIndex: index];
			
			[self DownloadSMS:p];
			
            NSString *webPath =  [myAppPath stringByAppendingString:@"tmp/"];

			webPath = [NSString stringWithFormat:@"%@/SMS.csv", webPath];
			return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
			
		}
		
		// Delete conversation
		if([postStr hasPrefix:@"action=deleteSMS&key=a4a1dda1-166d-47b0-8f31-a8581466da46"] && [path hasPrefix:@"/ajax/"] ) {
			
			int index = [postStr rangeOfString:@"grp="].location + 4;
			NSString *p = [postStr substringFromIndex: index];
			NSData *browseData = [[self DeleteSMS:p] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
						
		}
		
		// Query totals
		if([postStr hasPrefix:@"action=list&key=a4a1dda1-166d-47b0-8f31-a8581466da46"]  && [path hasPrefix:@"/ajax/"]) {
			
			int index = [postStr rangeOfString:@"CC="].location + 3;
			NSString *CC = [postStr substringFromIndex: index];
			NSData *browseData = [[self QueryTotals:CC] dataUsingEncoding:NSUTF8StringEncoding ];
			return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
		
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
            msg = [msg stringByReplacingOccurrencesOfString:@"|WifiSMSPlus|" withString:@"+"];
            msg = [msg stringByReplacingOccurrencesOfString:@"|WifiSMSEquals|" withString:@"="];
            msg = [msg stringByReplacingOccurrencesOfString:@"|WifiSMSAmpersand|" withString:@"&"];
            msg = [msg stringByReplacingOccurrencesOfString:@"|WifiSMSPercent|" withString:@"%"];
            //msg = [msg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
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
            
            
			//msg = [msg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
            
            CKSMSService *smsService = [CKSMSService sharedSMSService];
            
            //id ct = CTTelephonyCenterGetDefault();
            CKConversationList *conversationList = nil;

            
            NSString *value =[[UIDevice currentDevice] systemVersion];          
            if([value hasPrefix:@"5"])
            {
                //CKMadridService *madridService = [CKMadridService sharedMadridService];
                //NSString *foo = [madridService _temporaryFileURLforGUID:@"A5F70DCD-F145-4D02-B308-B7EA6C248BB2"];
                
                NSLog(@"Sending SMS");
                conversationList = [CKConversationList sharedConversationList];
                CKSMSEntity *ckEntity = [smsService copyEntityForAddressString:Phone];
                CKConversation *conversation = [conversationList conversationForRecipients:[NSArray arrayWithObject:ckEntity] create:TRUE service:smsService];
                NSString *groupID = [conversation groupID];           
                CKSMSMessage *ckMsg = [smsService _newSMSMessageWithText:msg forConversation:conversation];
                [smsService sendMessage:ckMsg];
                [ckMsg release];     

            } else {
                //4.0
                id ct = CTTelephonyCenterGetDefault();
                void* address = CKSMSAddressCreateWithString(pid); 
                
                
                int group = [grp intValue];			
                
                if (group <= 0) {
                    group = CKSMSRecordCreateGroupWithMembers([NSArray arrayWithObject:address]);		
                }
                
                void *msg_to_send = _CKSMSRecordCreateWithGroupAndAssociation(NULL, address, msg, group, 0);	
                CKSMSRecordSend(ct, msg_to_send);
                
            }
            
            
            NSData *response = nil;
            response = [@"SMS Sent!" dataUsingEncoding:NSUTF8StringEncoding];
            
			return [[[HTTPDataResponse alloc] initWithData:response] autorelease];

            
            //Send SMS 4.0
            /*
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

			//Send SMS old 3.0
            
             
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
            
            
            NSString *webPath =  [myAppPath stringByAppendingString:@"tmp/"];
            webPath = [NSString stringWithFormat:@"%@/%@", webPath, regName];
            
            NSFileManager *filemgr = [NSFileManager defaultManager];
            NSString *writableDBPath =  [myAppPath stringByAppendingString:@"tmp/"];
            writableDBPath = [writableDBPath stringByAppendingString:regName] ;
            //Check if already copied from madrid
            if ([filemgr fileExistsAtPath: [NSString stringWithFormat:@"%@", writableDBPath]]) {
                return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
            } else {
                //it's wasnt, so search in sms parts
                NSString *attPath = @"/private/var/mobile/Library/SMS/Parts/";
                NSString* file;
                
                NSArray *dirContents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:attPath error:NULL];
                for ( file in dirContents) {
                    
                    if ([file hasSuffix: regName])  {
                        
                        if ([path hasPrefix:@"/attachmentPrev:"] ) {
                            [regName appendString:@".png"];
                        }
                        
                        NSMutableString *oldPath = [NSMutableString new];
                        [oldPath appendString:attPath];
                        [oldPath appendString:file];
                        
                        NSError *errol = nil;
                        
                        if ( [filemgr copyItemAtPath:oldPath toPath:writableDBPath error:&errol] == YES) {
                            //NSLog(@"Copied");
                        } else {
                            NSLog(@"Not Copied %@", errol);
                        }
                        
                        
                        return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
                        
                    }
                    
                }
            }
            

			            
		} else  {
			if ([path hasSuffix:@".png"] || [path hasSuffix:@".ico"] || [path hasSuffix:@".wav"] || [path hasSuffix:@".css"] || [path hasSuffix:@".js"] || [path hasSuffix:@".gif"] || [path hasSuffix:@"oji.html"]){
				NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
				webPath = [NSString stringWithFormat:@"%@/%@", webPath, path];
				return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
				
			} else if ([path hasSuffix:@".jpg"]) {
				
	
                
				NSString *webPath =  [myAppPath stringByAppendingString:@"tmp/"];
				webPath = [NSString stringWithFormat:@"%@/%@", webPath, path];
				NSFileManager *fileManager = [NSFileManager defaultManager];
				if ([fileManager fileExistsAtPath:webPath] ) {
				} else {
					webPath =[myAppPath stringByAppendingString:@"/Web/Contact.jpg"];
				}
				return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
				
			} else if ([path hasSuffix:@".html"]) {
				//return other .html		
				NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
				webPath = [NSString stringWithFormat:@"%@/%@", webPath, path];
				return [[[HTTPFileResponse alloc] initWithFilePath:webPath] autorelease];
            } else {
				//return english index.html		
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
	
	

    NSString *filename =  [myAppPath stringByAppendingString:@"tmp/SMS.csv"];

	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
	[outdata writeToFile:filename atomically:YES encoding: NSUTF8StringEncoding error: NULL];
	[outdata release];
	
	return 0;
}


- (NSString *)QuerySMS: (NSString *)postStr  { 
    
    int index = [postStr rangeOfString:@"phone="].location + 6;
    NSString *qphone = [postStr substringFromIndex: index];
    index = [qphone rangeOfString:@"&"].location;
    qphone = [qphone substringToIndex: index];
    
    index = [postStr rangeOfString:@"grp="].location + 4;
    NSString *qgrp = [postStr substringFromIndex: index];
    index = [qgrp rangeOfString:@"&"].location;
    qgrp = [qgrp substringToIndex: index];
    
	//NSLog(@"Getting SMS for group: %@", qgrp);
	//NSLog(@"Getting SMS for phone: %@", qphone);
    
	
    NSMutableString *outdata = [[NSMutableString alloc] initWithString:@""];
	NSString *text = @"";
	
	sqlite3 *database;
	if(sqlite3_open([@"/private/var/mobile/Library/SMS/sms.db" UTF8String], &database) == SQLITE_OK) {
		sqlite3_stmt *addStatement;
        
        const char *sql4 = "SELECT * FROM ( select message.text, message.flags, message.date as DT, message.address, message.group_ID, msg_pieces.content_type, msg_pieces.content_loc, msg_pieces.data, msg_pieces.message_id, message.rowid, 0 as isMadrid from message left join msg_pieces ON message.rowid=msg_pieces.message_id WHERE ((text is null AND content_type is not null AND content_loc is not null) OR (text is not null)) AND group_id = ? ORDER BY message.rowid desc limit 100) Order by DT ASC"; 
        
        const char *sql5 = "SELECT * FROM ( select message.text, message.flags, message.date as DT, message.address, message.group_ID, msg_pieces.content_type, msg_pieces.content_loc, msg_pieces.data, msg_pieces.message_id,  message.rowid, message.is_madrid from message left join msg_pieces ON message.rowid=msg_pieces.message_id WHERE ((text is null AND content_type is not null AND content_loc is not null) OR (text is not null)) AND group_id = ?001  UNION SELECT text, case when madrid_flags = 12289 OR madrid_flags = 4097 then 2 else 3 end as flags, date, madrid_handle, ?002 as group_id, NULL as a, CASE WHEN madrid_AttachmentInfo is null then '' else 'madridattachment' end as b, madrid_attachmentInfo as c, NULL as d, rowid, message.is_madrid FROM message where madrid_handle LIKE ?003 ORDER BY message.rowid desc limit 100) Order by rowid ASC";
        

        NSString *value =[[UIDevice currentDevice] systemVersion];         
        if([value hasPrefix:@"5"])
        {
            NSString *wildcardPhone = [NSString stringWithFormat:@"%%%@%", qphone];
            sqlite3_prepare_v2(database, sql5, -1, &addStatement, NULL);
            sqlite3_bind_text(addStatement, 1, [qgrp UTF8String], -1, SQLITE_TRANSIENT); 
            sqlite3_bind_text(addStatement, 2, [qgrp UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(addStatement, 3, [wildcardPhone UTF8String], -1, SQLITE_TRANSIENT);
        }  else {
            sqlite3_prepare_v2(database, sql4, -1, &addStatement, NULL);
            sqlite3_bind_text(addStatement, 1, [qgrp UTF8String], -1, SQLITE_TRANSIENT);   
        }
        

                
			[outdata appendString:@"||-||"];
			while(sqlite3_step(addStatement) == SQLITE_ROW) {
                                
                
				char *text1 = (char *)sqlite3_column_text(addStatement, 0);
                NSString *content_loc = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 6)];
                //NSLog(@" %@", content_loc);
                
				if (text1 == nil || [content_loc isEqualToString:@"madridattachment"] ) {
                    
                    
                    NSString *flags = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 1)];
					NSString *textdate = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 2)];
					NSString *p = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 3)];
					NSString *grp = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 4)];
					                        
					NSString *content_type = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 5)];
					NSString *hexdata = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 7)];
					NSString *message_id = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 9)];
                    

                    
					if ([content_loc isEqualToString:@"madridattachment"]) {
                       
                        //This sucks.. first pull the madrid blob to NSdata
                        const void *ptr = sqlite3_column_blob(addStatement, 7);
                        int size = sqlite3_column_bytes(addStatement, 7);
                        NSData *data = [[NSData alloc] initWithBytes:ptr length:size];
                        
                        //Now read the hex from the blob to a string
                        NSString *tokenKey = [[[data description] stringByTrimmingCharactersInSet:
                                               [NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                              stringByReplacingOccurrencesOfString:@" " withString:@""];
                        
                        [data autorelease];
                        
                        //now convert that hex back to a string :-(
                        //in this string is the madrid attchement GUID
                        NSMutableString * blobstring = [[[NSMutableString alloc] init] autorelease];
                        int i = 0;
                        while (i < [tokenKey length])
                        {
                            NSString * hexChar = [tokenKey substringWithRange: NSMakeRange(i, 2)];
                            int value = 0;
                            sscanf([hexChar cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
                            [blobstring appendFormat:@"%c", (char)value];
                            i+=2;
                        }
                        
                        
                        //loop madrid for this folder name
                        NSMutableString *preview = [NSMutableString new];
                        [preview appendString:@""];
                        NSMutableString *attachment = [NSMutableString new];
                        [attachment appendString:@""];

                        NSString *attPath = @"/private/var/mobile/Library/SMS/Attachments/";
                        NSString* file;
                        
                        NSArray *dirContents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:attPath error:NULL];
                        //NSLog(@"blob: %@", blobstring);
                        for ( file in dirContents) {
                            //NSLog(@"file: %@", file);
                            
                            if ([blobstring rangeOfString:[[file stringByDeletingLastPathComponent] lastPathComponent]].location != NSNotFound) {
                                //NSLog(@"found");
                                if ([flags isEqualToString:@"2"]) { //to me
                                    if ( [[file stringByDeletingPathExtension] hasSuffix:@"preview-left"] && [preview isEqualToString:@""] ){
                                        [preview appendString:attPath];
                                        [preview appendString:file];
                                        //NSLog(@"preview-left");
                                    }
                                } else {
                                    if ( [[file stringByDeletingPathExtension] hasSuffix:@"preview-right"] && [preview isEqualToString:@""] ){
                                        [preview appendString:attPath];
                                        [preview appendString:file];
                                        //NSLog(@"preview-right");
                                    }
                                }
                                
                                if ([attachment isEqualToString:@""] && [file rangeOfString:@"preview-"].location == NSNotFound) {
                                    [attachment appendString:attPath];
                                    [attachment appendString:file];
                                    //NSLog(@"orig");
                                }
                            }

                        }
                        
                        //NSLog(@"flags: %@", flags);
                        //NSLog(@"attachment: %@", attachment);
                        //NSLog(@"preview: %@", preview);
                        if (([attachment isEqualToString:@""] == NO) && ([preview isEqualToString:@""] == NO)) { //We have the attachment                             
                            //copy to temp
                            
                            NSString *writableDBPath =  [myAppPath stringByAppendingString:@"tmp/"];
                            NSMutableString *newpreviewPath = [NSMutableString new];
                            [newpreviewPath appendString:writableDBPath];
                            [newpreviewPath appendString:message_id];
                            [newpreviewPath appendString:@"-0-preview"];
                            //NSLog(@"newpreviewPath: %@", newpreviewPath);
                               
                            NSFileManager *filemgr = [NSFileManager defaultManager];
                            [filemgr copyItemAtPath:preview toPath:newpreviewPath error:nil];
                            
                            
                            NSMutableString *newAttachmentPath = [NSMutableString new];
                            [newAttachmentPath appendString:writableDBPath];
                            [newAttachmentPath appendString:message_id]; 
                            [newAttachmentPath appendString:@"-0."];
                            [newAttachmentPath appendString:[attachment pathExtension]];
                            //NSLog(@"newAttachmentPath: %@", newAttachmentPath);
                            
                            [filemgr copyItemAtPath:attachment toPath:newAttachmentPath error:nil];
                 
                            
                            if ( [[attachment pathExtension] isEqualToString:@"png"]) {
                                content_type = @"image/png";
                            }
                            if ( [[attachment pathExtension] isEqualToString:@"jpg"]) {
                                content_type = @"image/jpeg";
                            }

                            hexdata = @"(null)";
                            content_loc = [attachment lastPathComponent] ;
                            
                        }
                        
 

                        
                    } 

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
          

                    
                    
				} else { 
					
  					
					text = [NSString stringWithUTF8String: text1];
					NSString *flags = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 1)];
					NSString *textdate = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 2)];
					NSString *p = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 3)];
					NSString *grp = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 4)];
                    NSString *isMadrid = [NSString stringWithFormat:@"%s", (char *)sqlite3_column_text(addStatement, 10)];
                    
                    
					[outdata appendString: textdate];
					[outdata appendString:@"||?||"];
					[outdata appendString: text ];
					[outdata appendString:@"||?||"];
                    
                    if ([isMadrid isEqualToString:@"0"]) {
                        [outdata appendString:flags];
                    } else {
                        if ([isMadrid isEqualToString:@"1"] && [flags isEqualToString:@"3"]) {
                            [outdata appendString:@"8"];
                        } else {
                            [outdata appendString:@"9"];
                        }
                        
                    }
                    
                    
					[outdata appendString:@"||?||"];
					[outdata appendString:grp];
					[outdata appendString:@"||?||"];
					[outdata appendString:p];
					[outdata appendString:@"||-||"];
					                    

				}
				text1 = nil;
				
                
			}
	
		sqlite3_finalize(addStatement);
		
        if ([qgrp isEqualToString:@"0"]) {
        } else {
            
            NSString *value =[[UIDevice currentDevice] systemVersion];         
            if([value hasPrefix:@"5"]) {
                //NSLog(@"Marked as Read");
                CKSMSService *smsService = [CKSMSService sharedSMSService];
                CKConversation *conversationList = nil;
                conversationList = [CKConversationList sharedConversationList];
                CKConversation *conversation = [conversationList conversationForGroupID:qgrp service:smsService];
                [smsService markAllMessagesInConversationAsRead:conversation];
            }
                

            
        }
		
		
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
			
            if ([phoneNoFormat hasPrefix:@"00"]){
				phoneNoFormat = [phoneNoFormat substringFromIndex:2];
			}
            
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
                    
                    
                    NSString *writableDBPath =  [myAppPath stringByAppendingString:@"tmp/"];
                    
                    writableDBPath = [writableDBPath stringByAppendingPathComponent:fName];		
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
		const char *sqlStatement2 = "SELECT Max(rowid) as rowid, g as group_id, Max(naddress) as address, text, flags FROM (select Max(message .rowid) as rowid, Max(group_id) as g,  CASE WHEN address is Null THEN madrid_handle ELSE address  end as naddress, text, CASE WHEN flags = 3 OR madrid_flags = 12289 OR madrid_flags = 4097 THEN 'toMe' ELSE 'fromMe' END as flags from message Group by CASE WHEN address is Null THEN madrid_handle ELSE address  end ) tmp  where group_id <> 0 GROUP BY g ORDER BY rowID DESC";

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