#import "Orangered.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.insanj.orangered.plist"
#define RANDOM_PHRASE(str) [@[@"Take a coffee break.", @"Relax.", @"Time to pick up that old ten-speed.", @"Reserve your cat facts.", @"Channel your zen.", @"Why stress?", @"Orange you glad I didn't say Orangered?", @"Let's chill."][arc4random_uniform(8)] stringByAppendingString:str];


/**************************************************************************************/
/************************ CRAVDelegate (used from first run) ****************************/
/***************************************************************************************/

@interface ORAlertViewDelegate : NSObject <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@implementation ORAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView cancelButtonIndex]) {
		return;
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer.dylib"]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Cydia&path=Orangered"]];
	}

	else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Orangered"]];
	}
}

@end

/***************************************************************************************/
/********************************* First Run Prompts  **********************************/
/***************************************************************************************/

static ORAlertViewDelegate *orangeredAlertDelegate;

%hook SBUIController

- (void)_deviceLockStateChanged:(NSNotification *)changed {
	%orig();

	NSNumber *state = changed.userInfo[@"kSBNotificationKeyState"];
	if (!state.boolValue) {
		orangeredAlertDelegate = [[ORAlertViewDelegate alloc] init];
	}
}

%end

%hook SBUIAnimationController

- (void)endAnimation {
	%orig();

	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
	if (orangeredAlertDelegate && !settings[@"didRun"]) {
		[settings setObject:@(YES) forKey:@"didRun"];
		[settings writeToFile:PREFS_PATH atomically:YES];

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Welcome to Orangered. You'll never miss a message again. Tap Begin to get started, or head to the settings anytime." delegate:orangeredAlertDelegate cancelButtonTitle:@"Later" otherButtonTitles:@"Begin", nil];
		[alert show];
	}
}

%end

/**************************************************************************************/
/*************************** Static Convenience Functions *****************************/
/**************************************************************************************/

static NSString * orangeredClientIdentifier() {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alienblue://"]]) {
		return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"com.designshed.alienbluehd" : @"com.designshed.alienblue";
	}

	for (NSString *s in @[@"com.NateChiger.Reddit", @"com.mediaspree.karma", @"com.nicholasleedesigns.upvote", @"com.jinsongniu.ialien", @"com.amleszk.amrc", @"com.tyanya.reddit"]) {
		SBApplicationController *controller = (SBApplicationController *)[%c(SBApplicationController) sharedInstance];
		if ([controller applicationWithDisplayIdentifier:s]) {
			return s;
		}
	}

	return @"com.apple.mobilesafari";
}

/**************************************************************************************/
/*********************** Tiny Helper Firing Object (T.H.F.O) **************************/
/**************************************************************************************/

@interface OrangeredProvider : NSObject <BBDataProvider>
- (void)fireAway;
@end

@implementation OrangeredProvider

+ (instancetype)sharedInstance {
	static OrangeredProvider *sharedInstance;

	static dispatch_once_t provider_token = 0;
	dispatch_once(&provider_token, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (void)pushBulletins:(NSMutableArray *)bulletins {
	BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.bulletin");

	for (BBBulletinRequest *bulletin in bulletins) {
		BBDataProviderAddBulletin(self, bulletin);
	}
}

- (NSArray *)bulletinsFilteredBy:(NSUInteger)filter count:(NSUInteger)count lastCleared:(NSDate *)lastCleared {
	return nil;
}

- (BBSectionInfo *)defaultSectionInfo {
	BBSectionInfo *sectionInfo = [BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit = 10;
	sectionInfo.sectionID = self.sectionIdentifier;
	return sectionInfo;
}

- (NSString *)sectionIdentifier {
	return @"com.insanj.orangered.bulletin";
}

- (NSString *)sectionDisplayName {
	return @"Orangered";
}

- (NSArray *)sortDescriptors {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}

- (void)fireAway {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil];
}

@end

/**************************************************************************************/
/************************* Primary RedditKit Communications ***************************/
/**************************************************************************************/

static NSTimer *orangeredTimer; // Shift to PCPersistantTimer / PCSimpleTimer someday

%ctor {
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.Check" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
    	// Load some preferences...
		NSDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];

		BOOL enabled = !preferences[@"enabled"] || [preferences[@"enabled"] boolValue];
		if (!enabled) {
			return;
		}

		NSString *username = preferences[@"username"];
		NSString *password = preferences[@"password"];

	    // Apparently RedditKit crashes out if either are nil? Bizarre.
	    if (!username || !password) {
	    	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
			request.title = @"Orangered";
			request.message = @"Uh-oh! Please check your username and password in the settings.";
			request.sectionID = @"com.apple.Preferences";
			[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
			return;
	    }

		BOOL alwaysNotify = !preferences[@"alwaysNotify"] || [preferences[@"alwaysNotify"] boolValue];
		BOOL alwaysMarkRead = preferences[@"alwaysMarkRead"] && [preferences[@"alwaysMarkRead"] boolValue];
		
		CGFloat intervalUnit = preferences[@"intervalControl"] ? [preferences[@"intervalControl"] floatValue] : 60.0;
		NSString *refreshIntervalString = preferences[@"refreshInterval"];
		CGFloat refreshInterval = (refreshIntervalString ? [refreshIntervalString floatValue] : 60.0) * intervalUnit;

    	orangeredTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:[OrangeredProvider sharedInstance] selector:@selector(fireAway) userInfo:nil repeats:NO];
		NSLog(@"[Orangered] Spun up timer (%@) to ping Reddit every %f seconds.", orangeredTimer, refreshInterval);

	    // Set-up some variables...
		RKClient *client = [RKClient sharedClient];
		if ([client isSignedIn] && (![client.currentUser.username isEqualToString:username])) {
			NSLog(@"[Orangered] Detected user changed, signing out...");
			[client signOut];
		}

		if (![client isSignedIn]) {
			NSLog(@"[Orangered] No existing user session detected, signing in...");

			// Sign in using RedditKit and supplied login information, and ping for unread messages.
	    	[client signInWithUsername:username password:password completion:^(NSError *error) {
	    		if (error) {
					NSLog(@"[Orangered] Error logging in: %@", [error localizedDescription]);

		        	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
					request.title = @"Orangered";
					request.message = [NSString stringWithFormat:@"Oops! There was a problem logging you in. Check syslog for error (%i).", (int)[error code]];
					request.sectionID = @"com.apple.Preferences";
					[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
					return;
	    		}

				// If properly signed in, check for unread messages...			
				[client unreadMessagesWithPagination:[RKPagination paginationWithLimit:100] markRead:alwaysMarkRead completion:^(NSArray *messages, RKPagination *pagination, NSError *error) {
			    	NSLog(@"[Orangered] Received unreadMessages response from Reddit: %@", messages);

					if (messages && messages.count > 0) {
						NSMutableArray *bulletins = [[NSMutableArray alloc] init];

						for (RKMessage *message in messages) {
		                	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
							bulletin.recordID = @"com.insanj.orangered.bulletin";
							bulletin.sectionID = orangeredClientIdentifier();

		        			bulletin.showsUnreadIndicator = message.unread;
							bulletin.title = message.subject;
							bulletin.subtitle = [@"from " stringByAppendingString:message.author];
							bulletin.message = message.messageBody;
							bulletin.date = message.created;

							bulletin.lastInterruptDate = [NSDate date];
							[bulletins addObject:bulletin];
							// [(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
						}

						[[OrangeredProvider sharedInstance] pushBulletins:bulletins];
					}
		
					else if (alwaysNotify) {
	                	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
						request.title = @"Orangered";
						request.message = RANDOM_PHRASE(@" No new messages found.");
						request.sectionID = orangeredClientIdentifier();

						[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
					}
	    		}];
			}];
		}

		else {
			NSLog(@"[Orangered] Existing user session detected, pinging Reddit...");

			// Check for unread messages...			
			[client unreadMessagesWithPagination:[RKPagination paginationWithLimit:100] markRead:alwaysMarkRead completion:^(NSArray *messages, RKPagination *pagination, NSError *error) {
		    	NSLog(@"[Orangered] Received unreadMessages response from Reddit: %@", messages);

				if (messages && messages.count > 0) {
					NSMutableArray *bulletins = [[NSMutableArray alloc] init];

					for (RKMessage *message in messages) {
	                	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
						bulletin.recordID = @"com.insanj.orangered.bulletin";
						bulletin.sectionID = orangeredClientIdentifier();

	        			bulletin.showsUnreadIndicator = message.unread;
						bulletin.title = message.subject;
						bulletin.subtitle = [@"from " stringByAppendingString:message.author];
						bulletin.message = message.messageBody;
						bulletin.date = message.created;

						bulletin.lastInterruptDate = [NSDate date];
						[bulletins addObject:bulletin];
						// [(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
					}

					[[OrangeredProvider sharedInstance] pushBulletins:bulletins];
				}
	
				else if (alwaysNotify) {
                	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
					request.title = @"Orangered";
					request.message = RANDOM_PHRASE(@" No new messages found.");
					request.sectionID = orangeredClientIdentifier();

					[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
				}
    		}];
		}
    }];
}
