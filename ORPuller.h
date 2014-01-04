#import "SBHeads.h"
#import "ORMessage.h"
#import "ORLogger.h"
#import "ORProvider.h"

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

@interface ORPuller : NSObject <NSURLConnectionDelegate>{
    NSString *username;
    NSString *password;
    NSArray *possibleErrors;
    ORLogger *logger;

    NSString *modhash;
}

-(ORPuller *)init;
-(ORPuller *)initWithUsername:(NSString *)user andPassword:(NSString *)pass;
-(void)loadCredentials;

-(void)run;
-(void)processHashData:(NSData *)data;

-(void)loadUnread;
-(void)processUnreadData:(NSData *)data;

-(void)searchForUnreadWithArray:(NSArray *)array;
-(void)quitAndHandleError:(NSError *)error orMessage:(NSString *)message;
-(NSDictionary *)settings;

@end