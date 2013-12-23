#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <stdlib.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

#import "CydiaSubstrate.h"
#import "NWURLConnection.h"
#import "BulletinBoard/BulletinBoard.h"
#import "SBBulletinBannerController.h"

#import "ORMessage.h"
#import "ORLogger.h"
#import "ORProvider.h"

#import "AESCrypt/NSData+AESCrypt.h"
#import "AESCrypt/NSString+AESCrypt.h"

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