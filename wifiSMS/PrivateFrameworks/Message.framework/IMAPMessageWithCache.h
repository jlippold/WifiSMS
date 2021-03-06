/* Generated by RuntimeBrowser on iPhone OS 3.0
   Image: /System/Library/PrivateFrameworks/Message.framework/Message
 */

@class NSData, MessageHeaders;



@interface IMAPMessageWithCache : IMAPMessage 
{
    NSData *_messageData;
    MessageHeaders *_headers;
}


- (void)dealloc;
- (id)messageData;
- (void)setMessageData:(id)arg1 isPartial:(BOOL)arg2;
- (BOOL)isMessageContentsLocallyAvailable;
- (id)headers;
- (void)setHeaders:(id)arg1;
- (id)headerData;

@end
