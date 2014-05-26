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

#define CLIENT_LIST @{@"com.designshed.alienblue" : @"Alien Blue", @"com.designshed.alienbluehd" : @"Alien Blue HD", \
					  @"com.rickharrison.narwhal" : @"narwhal", @"com.madeawkward.Cake" : @"Cake", \
					  @"com.syntaxstudios.reddme" : @"Reddme", @"com.appseedinc.aliens" : @"Aliens", \
					  @"com.amleszk.amrc" : @"amrc", @"com.tyanya.reddit" : @"Redditor", \
					  @"com.onelouder.BaconReader" : @"BaconReader", @"com.alexiscreuzot.reddito" : @"Reddito", \
					  @"com.mediaspree.karma" : @"Karma", @"com.craigmerchant.redd" : @"Redd", \
					  @"com.nicholasleedesigns.upvote" : @"Upvote", @"F2" : @"Flippit", \
					  @"6Q4UNB2LAJ" : @"MyReddit", @"com.NateChiger.MarsReddit" : @"Mars", \
					  @"com.aretesolutions.ojfree" : @"OJ Free", @"com.aretesolutions.oj" : @"OJ", \
					  @"com.lm.karmatrain" : @"Karma Train", @"com.jinsongniu.ialien" : @"iAlien"}


// Because of some weird DEBUG setting, this is a must...
// Other locations ORLOG can be found at (that I didn't feel like consolidating): ORListener.xm
#define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
// #define ORLOG(fmt, ...) 

// @interface BBServer (Private)
// + (instancetype)sharedInstance;
// @end

@interface UIApplication (Private)
- (void)_beginShowingNetworkActivityIndicator;
- (void)_hideNetworkActivityIndicator;
- (void)_endShowingNetworkActivityIndicator;
@end