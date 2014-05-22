#import "Orangered.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.insanj.orangered.plist"

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

/***************************************************************************************/
/**************************** Super-Import Server Saving  ******************************/
/***************************************************************************************/

static BBServer *orangeredServer;

%hook BBServer

- (id)init {
	orangeredServer = %orig();

	OrangeredProvider *sharedProvider = [OrangeredProvider sharedInstance];
	[orangeredServer _addDataProvider:sharedProvider forFactory:sharedProvider.factory];

	return orangeredServer;
}

%end

/**************************************************************************************/
/*************************** Static Convenience Functions *****************************/
/**************************************************************************************/

static NSString * orangeredPhrase() {
	NSArray *phrases = @[@"Take a coffee break.", @"Relax.", @"Time to pick up that old ten-speed.", @"Reserve your cat facts.", @"Channel your zen.", @"Why stress?", @"Orange you glad I didn't say Orangered?", @"Let's chill.", @"Head over to 4chan.", @"Buy yourself a tweak.", @"Hey, don't blame me.", @"Orangered powering down.", @"Have a nice day!", @"Don't even trip."];
	return [phrases[arc4random_uniform(phrases.count)] stringByAppendingString:@" No new messages found."];
}

/**************************************************************************************/
/************************* Primary RedditKit Communications ***************************/
/**************************************************************************************/

static NSTimer *orangeredTimer; // Shift to PCPersistantTimer / PCSimpleTimer someday

%ctor {
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.Check" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
    	// Load some preferences...
		NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];

		BOOL enabled = !preferences[@"enabled"] || [preferences[@"enabled"] boolValue];
		if (!enabled) {
			return;
		}

		NSString *username = preferences[@"username"];
		NSMutableString *passwordKey = [[NSMutableString alloc] initWithString:preferences[@"password"]];

	    // Apparently RedditKit crashes out if either are nil? Bizarre.
	    if (!username || !passwordKey) {
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

		// Let's get the real password, now that we've covered all the bases...
		NSError *getItemForKeyError;
		NSString *password = [FDKeychain itemForKey:passwordKey forService:@"Orangered" error:&getItemForKeyError];
		if (getItemForKeyError) {
			NSLog(@"[Orangered] Error trying to retrieve secured password, must have to secure it...");
			password = [NSString stringWithString:passwordKey];
			passwordKey = [[NSMutableString alloc] init];

		    for (int i = 0; i < password.length; i++) {
		        [passwordKey appendFormat:@"%c", arc4random_uniform(26) + 'a'];
		    }

			NSError *saveItemForKeyError;
			[FDKeychain saveItem:password forKey:passwordKey forService:@"Orangered" error:&saveItemForKeyError];
			if (saveItemForKeyError) {
				NSLog(@"[Orangered] Encountered an unfortunate error trying to secure password. Well shit. Cover your eyes: %@", saveItemForKeyError);
			}

			else {
				NSLog(@"[Orangered] Secured password successfully! :)");
				[preferences setObject:passwordKey forKey:@"password"];
				[preferences writeToFile:PREFS_PATH atomically:YES];
			}
		}

		else {
			NSLog(@"[Orangered] Accessed secured password successfully!");
		}

	    // Set-up some variables...
		RKClient *client = [RKClient sharedClient];
		RKListingCompletionBlock unreadCompletionBlock = ^(NSArray *messages, RKPagination *pagination, NSError *error) {
	    	NSLog(@"[Orangered] Received unreadMessages response from Reddit: %@", messages);
			if (alwaysMarkRead) {
				NSLog(@"[Orangered] Ensuring messages are all marked read...");
				[client markMessageArrayAsRead:messages completion:^(NSError *error) {
					NSLog(@"[Orangered] %@ cleared out unread messages.", error ? [NSString stringWithFormat:@"Failed (%@). Wishing I", [error localizedDescription]] : @"Successfully");
				}];
			}

			OrangeredProvider *provider = [OrangeredProvider sharedInstance];
	    	NSString *sectionID = [provider sectionIdentifier];

    		BBDataProviderWithdrawBulletinsWithRecordID(provider, @"com.insanj.orangered.bulletin");
			// [server withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionID];

			if (messages && messages.count > 0) {
            	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
				bulletin.recordID = @"com.insanj.orangered.bulletin";
				bulletin.lastInterruptDate = [NSDate date];
				bulletin.sectionID = sectionID;
				bulletin.defaultAction = [BBAction actionWithLaunchBundleID:sectionID callblock:nil];

				RKMessage *message = messages[0];
    			bulletin.showsUnreadIndicator = message.unread;
				bulletin.date = message.created;

				if (messages.count == 1) {
					bulletin.title = message.author;
					bulletin.subtitle = message.subject;
					bulletin.message = message.messageBody;
				}

				else {
					bulletin.title = @"Orangered";
					bulletin.message = [NSString stringWithFormat:@"You have %i unread messages.", (int)messages.count];
				}

				NSLog(@"[Orangered] Publishing bulletin request (%@) to provider (%@).", bulletin, provider);
				BBDataProviderAddBulletin(provider, bulletin);

				// [provider pushBulletin:bulletin intoServer:orangeredServer];
				// BBDataProviderAddBulletin(provider, bulletin);
				// [server _publishBulletinRequest:bulletin forSectionID:sectionID forDestinations:2];
				// [(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
			}

			else if (alwaysNotify) {
            	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
				request.title = @"Orangered";
				request.message = orangeredPhrase();
				request.sectionID = sectionID;

				[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
			}
		}; // end unreadCompletionBlock


		// Time to do some WERK
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
				[client unreadMessagesWithPagination:[RKPagination paginationWithLimit:100] markRead:alwaysMarkRead completion:unreadCompletionBlock];
			}];
		}

		else {
			NSLog(@"[Orangered] Existing user session detected, pinging Reddit...");
			// Check for unread messages...			
			[client unreadMessagesWithPagination:[RKPagination paginationWithLimit:100] markRead:alwaysMarkRead completion:unreadCompletionBlock];
		}
    }];
}
