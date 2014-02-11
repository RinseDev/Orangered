#line 1 "../ORProvider.xm"
#import "ORProvider.h"
#define ipad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

#include <logos/logos.h>
#include <substrate.h>
@class SBApplicationController; @class SBIconController; @class SpringBoard; 

static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SBApplicationController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBApplicationController"); } return _klass; }static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SBIconController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBIconController"); } return _klass; }static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }
#line 7 "../ORProvider.xm"
@implementation ORProvider
static BOOL ran, show;
static ORProvider *sharedProvider;
static NSDictionary *given;

+(ORProvider *)sharedProvider{
	static dispatch_once_t provider_token = 0;
    dispatch_once(&provider_token, ^{
        sharedProvider = [[self alloc] init];
    });

	return sharedProvider;
}

-(id)init{
	if(!self){
		self = [super init];
		logger = [[ORLogger alloc] initFromSource:@"ORProvider.m"];
		handle = [ORProvider determineHandle];
		name = [ORProvider determineName];
		sharedProvider = self;
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWithGiven:) name:@"ORGivenNotification" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(respring) name:@"ORRespringNotification" object:nil];
		[logger log:@"creating a listener for Reddit notifications..."];
	}
	
	return self;
}

-(BOOL)initialized{
	return (self != nil);
}

-(NSString *)sectionIdentifier{
	return handle;
}

-(NSArray *)sortDescriptors{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}

-(NSArray *)bulletinsFilteredBy:(unsigned)by count:(unsigned)count lastCleared:(id)cleared{
	return nil;
}

-(NSString *)sectionDisplayName{
	return name;
}

-(BBSectionInfo *)defaultSectionInfo{
	BBSectionInfo *sectionInfo = [BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit = 10;
	sectionInfo.sectionID = [self sectionIdentifier];
	return sectionInfo;
}

-(void)withdrawAndClear{
	[logger log:@"resetting badge and pulling notifications..."];

	[self setBadgeTo:0];
	BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.banner");
}

-(void)resetInfo{
	[logger log:@"resetting handle/name information and pulling notifications..."];
	BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.banner");

	name = [ORProvider determineName];
	handle = [ORProvider determineHandle];
}

-(void)handleNewNotification:(NSNotification *)notification{
	[logger log:@"received a valid notification from a Puller, sending it over..."];
	NSDictionary *notificationDict = [notification userInfo];
	[self handleWithMessages:[notificationDict objectForKey:@"data"]];
}

-(NSDictionary *)handleWithMessages:(NSArray *)array{
	[logger log:@"received some messages to route to push notifications..."];

	given = nil;
	messages = [[NSArray alloc] initWithArray:array];
	[self dataProviderDidLoad];
	return @{@"success": @YES};
}

-(void)handleWithGiven:(NSNotification *)notification{
	[logger log:@"received an alert noticiation..."];
	[self handleWithDictionary:[NSDictionary dictionaryWithDictionary:[notification userInfo]]];
}

-(NSDictionary *)handleWithDictionary:(NSDictionary *)dict{
	[logger log:@"handling with dictionary..."];

	given = dict;
	messages = nil;
	[self dataProviderDidLoad];
	return @{@"success": @YES};
}

-(void)dataProviderDidLoad{
	if(!ran){
		[logger log:@"tying up the strings for the bulletin sender, shouldn't notify..."];
		ran = YES;
		return;
	}

	if(given){
		[logger log:[NSString stringWithFormat:@"processing manual notification request (error or check): %@", given]];
		BBBulletinRequest *newBulletin = [[BBBulletinRequest alloc] init];
		newBulletin.sectionID = handle;
		newBulletin.defaultAction = [BBAction actionWithCallblock:^{
			[logger log:@"clearing!"];
			BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.banner");

			dispatch_async(dispatch_get_main_queue(), ^{
				[(SpringBoard *)[UIApplication sharedApplication] applicationOpenURL:[NSURL URLWithString:@"prefs:root=Orangered"] publicURLsOnly:NO];
			});
		}];

		newBulletin.bulletinID = [NSString stringWithFormat:@"com.insanj.orangered.banner_sent_%f", [[NSDate date] timeIntervalSince1970]];
		newBulletin.recordID = @"com.insanj.orangered.banner";
		newBulletin.publisherBulletinID = @"com.insanj.orangered";

		newBulletin.title = [given objectForKey:@"title"];
		newBulletin.message = [given objectForKey:@"message"];
		newBulletin.subtitle = [given objectForKey:@"subtitle"];		
		[newBulletin setUnlockActionLabel:[given objectForKey:@"label"]];

		newBulletin.date = [NSDate date];
		newBulletin.lastInterruptDate = [NSDate date];
		newBulletin.showsUnreadIndicator = NO;

		SystemSoundID ORBad;
		CFURLRef cfurl = (CFURLRef)CFBridgingRetain([[NSBundle bundleWithPath:@"/Library/PreferenceBundles/ORPreferences.bundle"] URLForResource:@"ORBad" withExtension:@"aiff"]);
		AudioServicesCreateSystemSoundID(cfurl, &ORBad);

		if([given objectForKey:@"sound"])
			newBulletin.sound = [BBSound alertSoundWithSystemSoundID:ORBad];

		show = [[given objectForKey:@"show"] boolValue];
		bulletin = newBulletin;

		NSString *stash;	
		stash = [newBulletin description];
		BBDataProviderAddBulletin(self, newBulletin);
		[logger log:[NSString stringWithFormat:@"dealt with manual alert: %@", given]];
	}

	else{
		[logger log:@"processing automatic notification request (message notification)"];
		BOOL notifyAlways = [[[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"notifyAlways"] boolValue];

		BBBulletinRequest *newBulletin = [[BBBulletinRequest alloc] init];
		newBulletin.sectionID = handle;
		void (^clear)(void) = ^{
			[logger log:@"clearing!"];
			
			[self setBadgeTo:0];
			BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.banner");
		};

		newBulletin.defaultAction = [name isEqualToString:@"Orangered"]?[BBAction actionWithLaunchURL:[NSURL URLWithString:@"http://reddit.com/message/unread"] callblock:clear]:[BBAction actionWithLaunchBundleID:handle callblock:clear];
		newBulletin.bulletinID = [NSString stringWithFormat:@"com.insanj.orangered.banner_sent_%f", [[NSDate date] timeIntervalSince1970]];
		newBulletin.recordID = @"com.insanj.orangered.banner";
		newBulletin.publisherBulletinID = @"com.insanj.orangered";
		newBulletin.title = name;
		newBulletin.date = [NSDate date];
		newBulletin.lastInterruptDate = [NSDate date];

		if(!messages || [messages count] == 0){
			[logger log:@"clearing due to no new messages"];
			
			[self setBadgeTo:0];
			BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.banner");

			if(notifyAlways || show){
				[logger log:@"no new messages were sent in the notification. Popping a banner that says so!"];	
				newBulletin.showsUnreadIndicator = NO;
				newBulletin.subtitle = @"";
				newBulletin.message = @"No new Reddit messages found!";

				NSString *stash;	
				stash = [newBulletin description];
				BBDataProviderAddBulletin(self, newBulletin);
			}
		}

		else{
			[logger log:@"found an array of new messages to notify the user of, starting to create and send..."];
		
			SystemSoundID ORGood;
			CFURLRef cfurl = (CFURLRef)CFBridgingRetain([[NSBundle bundleWithPath:@"/Library/PreferenceBundles/ORPreferences.bundle"] URLForResource:@"ORGood" withExtension:@"aiff"]);
			AudioServicesCreateSystemSoundID(cfurl, &ORGood);

			newBulletin.showsUnreadIndicator = YES;
			[self setBadgeTo:[messages count]];

			if([messages count] > 1){
				newBulletin.date = [NSDate date];
				newBulletin.title = name;
				newBulletin.message = [NSString stringWithFormat:@"You have %i unread messages.", (int)[messages count]];
			}

			else{
				ORMessage *m = [messages objectAtIndex:0];
				newBulletin.title = m.subject;
				newBulletin.subtitle = m.author;
				newBulletin.message = m.body;
			}

			newBulletin.sound = [BBSound alertSoundWithSystemSoundID:ORGood];
			[logger log:[NSString stringWithFormat:@"received a new bulletin:%@, whereas the old bulletin was:%@", newBulletin.message, bulletin.message]];
			if(![newBulletin.message isEqualToString:bulletin.message] || notifyAlways){
				bulletin = newBulletin;
				
				NSString *stash;	
				stash = [newBulletin description];
				BBDataProviderAddBulletin(self, newBulletin);
				[logger log:[NSString stringWithFormat:@"sending message bulletin with title: %@", newBulletin.title]];
			}

			else
				[logger log:@"already sent the requested bulletin, not sending again (on user request)..."];
		
		}
		
		show = NO;
	}
		
}


+(NSString *)determineName{

	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alienblue://"]])
		return @"Alien Blue";

	else if ([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:@"com.NateChiger.Reddit"])
		return @"Ruby";

	else if ([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:@"com.mediaspree.karma"])
		return @"Karma";

	else if ([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:@"com.nicholasleedesigns.upvote"])
		return @"upvote";

	else if ([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:@"com.jinsongniu.ialien"])
		return @"iAlien";

	else if ([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:@"com.amleszk.amrc"])
		return @"amrc";

	else if ([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:@"com.tyanya.reddit"])
		return @"Redditor";

	else
		return @"Orangered";
}

+(NSString *)determineHandle{

	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alienblue://"]]){
		if(ipad)
			return @"com.designshed.alienbluehd";
		else
			return @"com.designshed.alienblue";
	}

	NSArray *clients = [NSArray arrayWithObjects:@"com.NateChiger.Reddit", @"com.mediaspree.karma", @"com.nicholasleedesigns.upvote", @"com.jinsongniu.ialien", @"com.amleszk.amrc", @"com.tyanya.reddit", nil];
	for(NSString *s in clients)
		if([[_logos_static_class_lookup$SBApplicationController() sharedInstance] applicationWithDisplayIdentifier:s])
			return s;

	return @"com.apple.mobilesafari";
}

-(void)respring{
	[(SpringBoard *)[_logos_static_class_lookup$SpringBoard() sharedApplication] _relaunchSpringBoardNow];
}

-(void)setBadgeTo:(int)num{

	SBIconModel *iconModel = MSHookIvar<SBIconModel *>([_logos_static_class_lookup$SBIconController() sharedInstance], "_iconModel");

	if(num > 0)
		[[iconModel applicationIconForDisplayIdentifier:handle] setBadge:[NSString stringWithFormat:@"%i", num]];
	else
		[[iconModel applicationIconForDisplayIdentifier:handle] setBadge:nil];
}

-(void)dealloc {
	sharedProvider = nil;
	[self withdrawAndClear];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end
#line 306 "../ORProvider.xm"
