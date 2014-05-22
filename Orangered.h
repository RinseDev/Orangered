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

// Alien Blue, Alien Blue HD not included in list due to recognized URL-Scheme support
// Narwhal, Cake, Reddme, Aliens, amrc, Redditor, BaconReader, Reddito, Karma, Redd, Upvote, Flippit, MyReddit, Mars, OJ Free, OJ, Karma Train, iAlien
#define CLIENT_LIST @[@"com.rickharrison.narwhal", @"com.madeawkward.Cake", @"com.syntaxstudios.reddme", @"com.appseedinc.aliens", \
					  @"com.amleszk.amrc", @"com.tyanya.reddit", @"com.onelouder.BaconReader", @"com.alexiscreuzot.reddito", \
					  @"com.mediaspree.karma", @"com.craigmerchant.redd", @"com.nicholasleedesigns.upvote", @"F2", @"6Q4UNB2LAJ", \
					  @"com.NateChiger.MarsReddit", @"com.aretesolutions.ojfree", @"com.aretesolutions.oj", @"com.lm.karmatrain", \
					  @"com.jinsongniu.ialien"]

// @interface BBServer (Private)
// + (instancetype)sharedInstance;
// @end