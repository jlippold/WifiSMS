/* Generated by RuntimeBrowser on iPhone OS 3.0
   Image: /System/Library/PrivateFrameworks/OfficeImport.framework/OfficeImport
 */

/* RuntimeBrowser encountered an ivar type encoding it does not handle. 
   See Warning(s) below.
 */

@class WDAContent, NSString, WDText, WDDocument;



@interface WDATextBox : NSObject 
{
    NSInteger mTextId;

  /* Error parsing encoded ivar type info: B */
    /* Warning: Unrecognized filer type: 'B' using 'void*' */ void*mOle;

    WDDocument *mDocument;
    WDAContent *mParent;
    WDText *mText;
    NSString *mNextTextBox;
}


- (void)dealloc;
- (id)document;
- (void)setDocument:(id)arg1;
- (NSInteger)textId;
- (void)setTextId:(NSInteger)arg1;
- (BOOL)isOle;
- (void)setOle:(BOOL)arg1;
- (id)parent;
- (void)setParent:(id)arg1;
- (id)text;
- (void)setText:(id)arg1;
- (id)nextTextBox;
- (void)setNextTextBox:(id)arg1;

@end
