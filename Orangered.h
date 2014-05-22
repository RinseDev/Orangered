#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBBulletinBannerController.h>
#import <BulletinBoard/BulletinBoard.h>

#import "Communication/AFNetworking.h"
#import "Communication/RedditKit.h"
#import "Communication/Mantle.h"

#import "Communication/FDKeychain.h"

#import "substrate.h"
#import <objc/runtime.h>

#import "ORProviders.h"

#ifdef DEBUG
	#define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define ORLOG(fmt, ...) 
#endif

// @interface BBServer (Private)
// + (instancetype)sharedInstance;
// @end