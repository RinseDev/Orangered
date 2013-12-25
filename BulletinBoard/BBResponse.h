/* Generated by RuntimeBrowser.
   Image: /Applications/Xcode5.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk/System/Library/PrivateFrameworks/BulletinBoard.framework/BulletinBoard
 */

/* RuntimeBrowser encountered an ivar type encoding it does not handle. 
   See Warning(s) below.
 */

@class NSArray, NSString, BBAssertion;

@interface BBResponse : NSObject <NSCoding> {
    BBAssertion *_lifeAssertion;

  /* Unexpected information at end of encoded ivar type: ? */
  /* Error parsing encoded ivar type info: @? */
    id _sendBlock;

    NSString *_bulletinID;
    BOOL _sent;
    NSString *_replyText;
    NSArray *_lifeAssertions;
    int _actionType;
    NSString *_buttonID;
}

@property(copy) NSString * replyText;
@property(copy) NSArray * lifeAssertions;
@property(copy) id sendBlock;
@property(retain) NSString * bulletinID;
@property int actionType;
@property(copy) NSString * buttonID;


- (void)setSendBlock:(id)arg1;
- (void)setLifeAssertions:(id)arg1;
- (id)lifeAssertions;
- (id)buttonID;
- (id)replyText;
- (id)bulletinID;
- (void)setButtonID:(id)arg1;
- (void)setReplyText:(id)arg1;
- (void)setBulletinID:(id)arg1;
- (id)sendBlock;
- (void)setActionType:(int)arg1;
- (int)actionType;
- (void)dealloc;
- (void)send;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;

@end
