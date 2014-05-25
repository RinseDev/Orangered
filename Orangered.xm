#import "Orangered.h"

/**************************************************************************************/
/************************ CRAVDelegate (used from first run) ****************************/
/***************************************************************************************/

@interface ORAlertViewDelegate : NSObject <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
+ (NSURL *)sharedLaunchPreferencesURL;
@end

@implementation ORAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView cancelButtonIndex]) {
		return;
	}

	// [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Preferences" object:nil userInfo:@{ @"url" : [ORAlertViewDelegate sharedLaunchPreferencesURL] }];
	[[UIApplication sharedApplication] openURL:[ORAlertViewDelegate sharedLaunchPreferencesURL]];
}

+ (NSURL *)sharedLaunchPreferencesURL {
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/PreferenceOrganizer.dylib"]) {
		return [NSURL URLWithString:@"prefs:root=Cydia&path=Orangered"];
	}

	else {
		return [NSURL URLWithString:@"prefs:root=Orangered"];
	}
}

@end

/***************************************************************************************/
/********************************* First Run Prompts  **********************************/
/***************************************************************************************/

static ORAlertViewDelegate *orangeredAlertDelegate;
static BOOL checkOnUnlock;

%hook SBLockScreenManager

- (void)_finishUIUnlockFromSource:(NSInteger)source withOptions:(NSDictionary *)options {
	%orig;

	if (![NSDictionary dictionaryWithContentsOfFile:PREFS_PATH]) {
		ORLOG(@"First run, prompting...");
		[@{} writeToFile:PREFS_PATH atomically:YES];

		orangeredAlertDelegate = [[ORAlertViewDelegate alloc] init];
		UIAlertView *orangeredAlert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Welcome to Orangered. You'll never miss a message again. Tap Begin to get started, or head to the settings anytime." delegate:orangeredAlertDelegate cancelButtonTitle:@"Later" otherButtonTitles:@"Begin", nil];
		[orangeredAlert show];
	}

	else if (checkOnUnlock) {
		checkOnUnlock = NO;

		ORLOG(@"Checking on unlock due to authentication issues...");
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil];
	}
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig();

	ORLOG(@"Sending check message from SpringBoard...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil];
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

static PCPersistentTimer *orangeredTimer;

%ctor {
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.Preferences" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
    	ORLOG(@"Launching preferences based on: %@", notification);
    	[[UIApplication sharedApplication] openURL:notification.userInfo[@"url"]];
    }];

    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.Check" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
    	// Let's cancel our appointments...
    	[orangeredTimer invalidate];

    	// Load some preferences...
		NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];

		BOOL enabled = !preferences[@"enabled"] || [preferences[@"enabled"] boolValue];
		if (!enabled) {
			return;
		}

		CGFloat intervalUnit = preferences[@"intervalControl"] ? [preferences[@"intervalControl"] floatValue] : 60.0;
		NSString *refreshIntervalString = preferences[@"refreshInterval"];
		CGFloat refreshInterval = (refreshIntervalString ? [refreshIntervalString floatValue] : 60.0) * intervalUnit;

		orangeredTimer = [[PCPersistentTimer alloc] initWithTimeInterval:refreshInterval serviceIdentifier:@"com.insanj.orangered" target:[OrangeredProvider sharedInstance] selector:@selector(fireAway) userInfo:nil];
		[orangeredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];

		ORLOG(@"Spun up timer (%@) to ping Reddit every %f seconds.", orangeredTimer, refreshInterval);

		NSString *username = preferences[@"username"];
		NSString *passwordKey = preferences[@"password"];

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
		
		// Let's get the real password, now that we've covered all the bases...
		NSError *getItemForKeyError;
		NSString *password = [FDKeychain itemForKey:passwordKey forService:@"Orangered" error:&getItemForKeyError];
		ORLOG(@"------- %i", (int)getItemForKeyError.code);
		if (getItemForKeyError.code == -25308) {
			ORLOG(@"Error trying to retrieve secured password, postponing until we're not at the lockscreen...");
			checkOnUnlock = YES;
			return;
		}

		if (getItemForKeyError) {
			ORLOG(@"Error trying to retrieve secured password, must have to secure it...");
			password = [NSString stringWithString:passwordKey];
			NSMutableString *mutableKey = [[NSMutableString alloc] initWithString:passwordKey];

		    for (int i = 0; i < password.length; i++) {
		        [mutableKey appendFormat:@"%c", arc4random_uniform(26) + 'a'];
		    }

			NSError *saveItemForKeyError;
			[FDKeychain saveItem:password forKey:mutableKey forService:@"Orangered" error:&saveItemForKeyError];
			if (saveItemForKeyError) {
				ORLOG(@"Encountered an unfortunate error trying to secure password. Well shit. Cover your eyes: %@", saveItemForKeyError);
			}

			else {
				ORLOG(@"Secured password successfully! :)");
				[preferences setObject:mutableKey forKey:@"password"];
				[preferences writeToFile:PREFS_PATH atomically:YES];
			}
		}

		else {
			ORLOG(@"Accessed secured password successfully!");
		}

	    // Set-up some variables...
		RKClient *client = [RKClient sharedClient];
		RKListingCompletionBlock unreadCompletionBlock = ^(NSArray *messages, RKPagination *pagination, NSError *error) {
			[[UIApplication sharedApplication] _endShowingNetworkActivityIndicator];
	    	ORLOG(@"Received unreadMessages response from Reddit: %@", messages);

			if (alwaysMarkRead) {
				ORLOG(@"Ensuring messages are all marked read...");
				[client markMessageArrayAsRead:messages completion:^(NSError *error) {
					ORLOG(@"%@ cleared out unread messages.", error ? [NSString stringWithFormat:@"Failed (%@). Wishing I", [error localizedDescription]] : @"Successfully");
				}];
			}

			OrangeredProvider *provider = [OrangeredProvider sharedInstance];
	    	NSString *sectionID = [provider sectionIdentifier];

	    	// [orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionID];
    		BBDataProviderWithdrawBulletinsWithRecordID(provider, sectionID);
			// [server withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionID];

			if (messages && messages.count > 0) {
            	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
				bulletin.recordID = @"com.insanj.orangered.bulletin";
				bulletin.sectionID = sectionID;
				bulletin.defaultAction = [BBAction actionWithLaunchBundleID:sectionID callblock:nil];
				bulletin.date = [NSDate date];

				NSString *ringtoneIdentifier = preferences[@"alertTone"];
				if (ringtoneIdentifier) {
					BBSound *savedSound = [[BBSound alloc] initWithRingtone:ringtoneIdentifier vibrationPattern:nil repeats:NO];
					ORLOG(@"Assigning saved sound %@ to ringtone %@ to play...", ringtoneIdentifier, savedSound);
					bulletin.sound = savedSound;
				}

				RKMessage *message = messages[0];
    			bulletin.showsUnreadIndicator = message.unread;

				if (messages.count == 1) {
					bulletin.title = message.author;
					bulletin.subtitle = message.subject;
					bulletin.message = message.messageBody;
				}

				else {
					bulletin.title = @"Orangered";
					bulletin.message = [NSString stringWithFormat:@"You have %i unread messages.", (int)messages.count];
				}

				ORLOG(@"Publishing bulletin request (%@) to provider (%@).", bulletin, provider);
				// [orangeredServer _publishBulletinRequest:bulletin forSectionID:sectionID forDestinations:2];
				// [orangeredServer publishBulletinRequest:bulletin destinations:2];

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
			ORLOG(@"Detected user changed, signing out...");
			[client signOut];
		}

		[[UIApplication sharedApplication] _beginShowingNetworkActivityIndicator];

		if (![client isSignedIn]) {
			ORLOG(@"No existing user session detected, signing in...");

			// Sign in using RedditKit and supplied login information, and ping for unread messages.
	    	[client signInWithUsername:username password:password completion:^(NSError *error) {
	    		if (error) {
	    			ORLOG(@"Encountered error (%@, %@), pushing bulletin request...", error, error.userInfo);
		        	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
					bulletin.recordID = @"com.insanj.orangered.bulletin";
					bulletin.title = @"Orangered";

					NSString *relevantMessage;
					switch ((int)error.code) {
						default:
							relevantMessage = [NSString stringWithFormat:@"Oops! Check here to get more details about the error (%i).", (int)[error code]];
							break;
						case 203:
							 relevantMessage = [NSString stringWithFormat:@"Invalid credentials. Reddit can't log you in with that username or password."];
						case 204:
							 relevantMessage = [NSString stringWithFormat:@"Reddit has rate limited your device. Wait before using Orangered again!"];
							 break;
					}

					bulletin.message = relevantMessage;
					bulletin.sectionID = @"com.apple.Preferences";
					bulletin.date = [NSDate date];

					UIAlertView __block *errorAlert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
					bulletin.defaultAction = [BBAction actionWithLaunchURL:[ORAlertViewDelegate sharedLaunchPreferencesURL]  callblock:^{
						[errorAlert show];
					}];

					BBDataProviderAddBulletin([OrangeredProvider sharedInstance], bulletin);
					[[UIApplication sharedApplication] _endShowingNetworkActivityIndicator];
					return;
	    		}

				// If properly signed in, check for unread messages...			
				[client unreadMessagesWithPagination:[RKPagination paginationWithLimit:100] markRead:alwaysMarkRead completion:unreadCompletionBlock];
			}];
		}

		else {
			ORLOG(@"Existing user session detected, pinging Reddit...");
			// Check for unread messages...			
			[client unreadMessagesWithPagination:[RKPagination paginationWithLimit:100] markRead:alwaysMarkRead completion:unreadCompletionBlock];
		}
    }];
}
