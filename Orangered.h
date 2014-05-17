#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#import "Communication/AFNetworking.h"
#import "Communication/RedditKit.h"
#import "Communication/ClassyHelper.h"
#import "Communication/Mantle.h"

#import "substrate.h"

#ifdef DEBUG
	#define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define ORLOG(fmt, ...) 
#endif

@interface BBBulletinRequest : NSObject
@property (nonatomic, retain) NSString *title, *message, *sectionID;
@end

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (void)observer:(id)observer addBulletin:(BBBulletinRequest *)bulletin forFeed:(int)feed;
@end

@interface RKClient (Refresh)
-(void)refresh;
@end
