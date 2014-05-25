#import <UIKit/UIKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <UIKit/UITableViewCell+Private.h>
#import <Twitter/Twitter.h>
#import <objc/runtime.h>

#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBBulletinBannerController.h>
#import <BulletinBoard/BulletinBoard.h>
#import <PersistentConnection/PersistentConnection.h>
#import <ToneLibrary/ToneLibrary.h>

#import <libactivator/libactivator.h>
#import "substrate.h"

#import "Communication/AFNetworking.h"
#import "Communication/RedditKit.h"
#import "Communication/Mantle.h"
#import "Communication/FDKeychain.h"

#import "ORProviders.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.insanj.orangered.plist"
#define URL_ENCODE(string) [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)(string), NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8) autorelease]
#define TINT_COLOR [UIColor colorWithRed:232.0/255.0 green:98.0/255.0 blue:49.0/255.0 alpha:1.0];

// Alien Blue, Alien Blue HD not included in list due to recognized URL-Scheme support
// Narwhal, Cake, Reddme, Aliens, amrc, Redditor, BaconReader, Reddito, Karma, Redd, Upvote, Flippit, MyReddit, Mars, OJ Free, OJ, Karma Train, iAlien
#define CLIENT_LIST @[@"com.rickharrison.narwhal", @"com.madeawkward.Cake", @"com.syntaxstudios.reddme", @"com.appseedinc.aliens", \
					  @"com.amleszk.amrc", @"com.tyanya.reddit", @"com.onelouder.BaconReader", @"com.alexiscreuzot.reddito", \
					  @"com.mediaspree.karma", @"com.craigmerchant.redd", @"com.nicholasleedesigns.upvote", @"F2", @"6Q4UNB2LAJ", \
					  @"com.NateChiger.MarsReddit", @"com.aretesolutions.ojfree", @"com.aretesolutions.oj", @"com.lm.karmatrain", \
					  @"com.jinsongniu.ialien"]

#define __DEBUG__ 1
#ifdef __DEBUG__
	#define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
	#define ORLOG(fmt, ...) 
#endif

// @interface BBServer (Private)
// + (instancetype)sharedInstance;
// @end

@interface UIApplication (Private)
- (void)_beginShowingNetworkActivityIndicator;
- (void)_hideNetworkActivityIndicator;
- (void)_endShowingNetworkActivityIndicator;
@end