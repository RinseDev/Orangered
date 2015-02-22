#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <SpringBoard/SpringBoard.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <Cephei/HBPreferences.h>
#import "substrate.h"

#define PREFS [[HBPreferences alloc] initWithIdentifier:@"com.insanj.orangered"]
#define CLIENTS @{@"com.reddit.alienblue" : @"Alien Blue", @"com.designshed.alienblue" : @"Alien Blue", @"com.designshed.alienbluehd" : @"Alien Blue HD", \
				@"com.madeawkward.beam" : @"beam", @"com.rickharrison.narwhal" : @"narwhal", @"com.madeawkward.Cake" : @"Cake", \
				@"com.yapstudios.appstore.feedworthy" : @"Feedworthy", @"com.biscuitapp.biscuit" : @"Biscuit", \
				@"com.syntaxstudios.reddme" : @"Reddme", @"com.appseedinc.aliens" : @"Aliens", \
				@"com.amleszk.amrc" : @"amrc", @"com.tyanya.reddit" : @"Redditor", \
				@"com.onelouder.BaconReader" : @"BaconReader", @"com.alexiscreuzot.reddito" : @"Reddito", \
				@"com.mediaspree.karma" : @"Karma", @"com.craigmerchant.redd" : @"Redd", \
				@"com.nicholasleedesigns.upvote" : @"Upvote", @"F2" : @"Flippit", \
				@"6Q4UNB2LAJ" : @"MyReddit", @"com.NateChiger.MarsReddit" : @"Mars", \
				@"com.aretesolutions.ojfree" : @"OJ Free", @"com.aretesolutions.oj" : @"OJ", \
				@"com.lm.karmatrain" : @"Karma Train", @"com.jinsongniu.ialien" : @"iAlien"}


// Because of some weird DEBUG effects in Mantle, this is a must...
// Other locations ORLOG can be found at (that I didn't feel like consolidating): ORListener.xm
#define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
// #define ORLOG(fmt, ...) 

static UIColor *kOrangeredTintColor = [UIColor colorWithRed:232.0/255.0 green:98.0/255.0 blue:49.0/255.0 alpha:1.0];
static NSString *kOrangeredErrorNotificationName = @"Orangered.Notification.Error", *kOrangeredOpenNCNotificationName = @"Orangered.Notification.OpenNC", *kOrangeredOpenPrefsNotificationName = @"Orangered.Notification.Prefs", *kOrangeredCheckNotificationName = @"Orangered.Notification.Check", *kOrangeredIntervalNotificationName = @"Orangered.Notification.Interval", *kOrangeredSecureNotificationName = @"Orangered.Notification.Secure";

@interface ORAlertViewDelegate : NSObject <UIAlertViewDelegate>

+ (NSURL *)sharedLaunchPreferencesURL;

@end
