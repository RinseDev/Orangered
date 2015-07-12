#import "Orangered.h"
#import "ORProviders.h"
#import "External/FDKeychain/FDKeychain.h" 
#import "External/RedditKit/RedditKit.h"
#import "External/RedditKit/AFNetworking/AFNetworking.h"
#import <PersistentConnection/PersistentConnection.h>
#import <UIKit/UIApplication+Private.h>
#import <BulletinBoard/BulletinBoard.h>
#import <SpringBoard/SBMediaController.h>
#import <ToneLibrary/ToneLibrary.h>

/*
 /$$                       /$$                    
| $$                      | $$                    
| $$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$ 
| $$__  $$ |____  $$ /$$__  $$ /$$__  $$ /$$__  $$
| $$  \ $$  /$$$$$$$| $$  | $$| $$  \ $$| $$$$$$$$
| $$  | $$ /$$__  $$| $$  | $$| $$  | $$| $$_____/
| $$$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$|  $$$$$$$
|_______/  \_______/ \_______/ \____  $$ \_______/
                               /$$  \ $$          
                              |  $$$$$$/          
                               \______/                                                                                                                                                                      
*/
static void orangeredSetDisplayIdentifierBadge(NSString *displayIdentifier, NSInteger badgeValue) {
	SBIconModel *iconModel = MSHookIvar<SBIconModel *>([%c(SBIconController) sharedInstance], "_iconModel");
	NSString *stringBadgeValue;
	if (badgeValue > 0)  {
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
		[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		stringBadgeValue = [formatter stringForObjectValue:@(badgeValue)];
	}

	SBApplicationIcon *clientAppIcon = [iconModel applicationIconForBundleIdentifier:displayIdentifier]; 
	[clientAppIcon setBadge:stringBadgeValue];

	ORLOG(@"set badge %@ to %@", stringBadgeValue, clientAppIcon);
}

/*
 /$$                 /$$ /$$             /$$     /$$          
| $$                | $$| $$            | $$    |__/          
| $$$$$$$  /$$   /$$| $$| $$  /$$$$$$  /$$$$$$   /$$ /$$$$$$$ 
| $$__  $$| $$  | $$| $$| $$ /$$__  $$|_  $$_/  | $$| $$__  $$
| $$  \ $$| $$  | $$| $$| $$| $$$$$$$$  | $$    | $$| $$  \ $$
| $$  | $$| $$  | $$| $$| $$| $$_____/  | $$ /$$| $$| $$  | $$
| $$$$$$$/|  $$$$$$/| $$| $$|  $$$$$$$  |  $$$$/| $$| $$  | $$
|_______/  \______/ |__/|__/ \_______/   \___/  |__/|__/  |__/
*/        
static void orangeredAddBulletin(BBServer *server, OrangeredProvider *provider, BBBulletinRequest *bulletin) {
	BBDataProviderAddBulletin(provider, bulletin); // This works in iOS 8.1.2
}

static ORAlertViewDelegate *orangeredAlertDelegate;
static PCSimpleTimer *orangeredTimer;
static NSError *orangeredError;
static BOOL checkOnUnlock;
static NSTimeInterval lastRequestInterval;
static NSDate *lastMessageDate;
static NSMutableSet *previousUnreadMessages;
static NSDateFormatter *orangeredDateFormatter;
static NSString *previousClientIdentifier;

/*                                                                                                                                         
                     /$$                                           /$$
                    | $$                                          | $$
  /$$$$$$  /$$$$$$$ | $$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$$
 /$$__  $$| $$__  $$| $$__  $$ /$$__  $$ |____  $$ /$$__  $$ /$$__  $$
| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$  /$$$$$$$| $$  \__/| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$  | $$ /$$__  $$| $$      | $$  | $$
|  $$$$$$/| $$  | $$| $$$$$$$/|  $$$$$$/|  $$$$$$$| $$      |  $$$$$$$
 \______/ |__/  |__/|_______/  \______/  \_______/|__/       \_______/                                                                                                                                                                      
*/
@implementation ORAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	HBPreferences *preferences = PREFS;
	[preferences setBool:YES forKey:@"Ran Before"];

	if (buttonIndex == [alertView cancelButtonIndex]) {
		return;
	}

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

/*
                               /$$                     /$$                                           /$$
                              |__/                    | $$                                          | $$
  /$$$$$$$  /$$$$$$   /$$$$$$  /$$ /$$$$$$$   /$$$$$$ | $$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$$
 /$$_____/ /$$__  $$ /$$__  $$| $$| $$__  $$ /$$__  $$| $$__  $$ /$$__  $$ |____  $$ /$$__  $$ /$$__  $$
|  $$$$$$ | $$  \ $$| $$  \__/| $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$  /$$$$$$$| $$  \__/| $$  | $$
 \____  $$| $$  | $$| $$      | $$| $$  | $$| $$  | $$| $$  | $$| $$  | $$ /$$__  $$| $$      | $$  | $$
 /$$$$$$$/| $$$$$$$/| $$      | $$| $$  | $$|  $$$$$$$| $$$$$$$/|  $$$$$$/|  $$$$$$$| $$      |  $$$$$$$
|_______/ | $$____/ |__/      |__/|__/  |__/ \____  $$|_______/  \______/  \_______/|__/       \_______/
          | $$                               /$$  \ $$                                                  
          | $$                              |  $$$$$$/                                                  
          |__/                               \______/    
*/                                               

%hook SBLockScreenManager

- (void)_finishUIUnlockFromSource:(NSInteger)source withOptions:(NSDictionary *)options {
	%orig;

	HBPreferences *preferences = PREFS;
	if (![preferences boolForKey:@"Ran Before" default:NO]) {
		ORLOG(@"First run, prompting...");

		orangeredAlertDelegate = [[ORAlertViewDelegate alloc] init];
		UIAlertView *orangeredAlert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Welcome to Orangered. You'll never miss a message again. Tap Begin to get started, or head to the settings anytime." delegate:orangeredAlertDelegate cancelButtonTitle:@"Later" otherButtonTitles:@"Begin", nil];
		[orangeredAlert show];
	}

	else if (checkOnUnlock) {
		checkOnUnlock = NO;

		ORLOG(@"Checking on unlock due to authentication issues...");
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredCheckNotificationName object:nil userInfo:@{ @"sender" : @"SpringBoard" }];
	}
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig();

	orangeredDateFormatter = [[NSDateFormatter alloc] init];
	[orangeredDateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
	ORLOG(@"Sending check message from SpringBoard...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredCheckNotificationName object:nil userInfo:@{ @"sender" : @"SpringBoard" }];
}

%end

/*
                                                            
                                                            
  /$$$$$$$  /$$$$$$   /$$$$$$  /$$    /$$ /$$$$$$   /$$$$$$ 
 /$$_____/ /$$__  $$ /$$__  $$|  $$  /$$//$$__  $$ /$$__  $$
|  $$$$$$ | $$$$$$$$| $$  \__/ \  $$/$$/| $$$$$$$$| $$  \__/
 \____  $$| $$_____/| $$        \  $$$/ | $$_____/| $$      
 /$$$$$$$/|  $$$$$$$| $$         \  $/  |  $$$$$$$| $$      
|_______/  \_______/|__/          \_/    \_______/|__/      
*/                                                       
static BBServer *orangeredServer;
static BBDataProviderConnection *dataProviderConnection;

%hook BBServer

- (id)init {
	orangeredServer = %orig();

	return orangeredServer;
}

- (void)_loadDataProvidersAndSettings {
	%orig;
	[dataProviderConnection addDataProvider:[OrangeredProvider sharedInstance]];
}

%end

%hook BBDataProviderConnection

- (id)initWithServiceName:(id)arg1 onQueue:(id)arg2 {
	dataProviderConnection = self;
	return %orig;
}

%end


/*
            /$$                        
           | $$                        
  /$$$$$$$/$$$$$$    /$$$$$$   /$$$$$$ 
 /$$_____/_  $$_/   /$$__  $$ /$$__  $$
| $$       | $$    | $$  \ $$| $$  \__/
| $$       | $$ /$$| $$  | $$| $$      
|  $$$$$$$ |  $$$$/|  $$$$$$/| $$      
 \_______/  \___/   \______/ |__/      

*/

%ctor {
	HBPreferences *orangeredPreferences = PREFS;

	/*
	                                                                  
	  /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$        /$$$$$$$   /$$$$$$$
	 /$$__  $$ /$$__  $$ /$$__  $$| $$__  $$      | $$__  $$ /$$_____/
	| $$  \ $$| $$  \ $$| $$$$$$$$| $$  \ $$      | $$  \ $$| $$      
	| $$  | $$| $$  | $$| $$_____/| $$  | $$      | $$  | $$| $$      
	|  $$$$$$/| $$$$$$$/|  $$$$$$$| $$  | $$      | $$  | $$|  $$$$$$$
	 \______/ | $$____/  \_______/|__/  |__/      |__/  |__/ \_______/
	          | $$                                                    
	          | $$                                                    
	          |__/                                                    
      */
	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:kOrangeredOpenNCNotificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		NSString *clientIdentifier = [orangeredPreferences objectForKey:@"clientIdentifier" default:nil];
		NSURL *notificationCenterURL;
		if (clientIdentifier) {
			notificationCenterURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&path=%@", [%c(PSNotificationSettingsDetail) preferencesURL].absoluteString, clientIdentifier]];
		}

		else {
			notificationCenterURL = [%c(PSNotificationSettingsDetail) preferencesURL];
		}

		[[UIApplication sharedApplication] openURL:notificationCenterURL];
	}];

	/*

	                                                  
	  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$ 
	 /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$
	| $$$$$$$$| $$  \__/| $$  \__/| $$  \ $$| $$  \__/
	| $$_____/| $$      | $$      | $$  | $$| $$      
	|  $$$$$$$| $$      | $$      |  $$$$$$/| $$      
	 \_______/|__/      |__/       \______/ |__/      
	                                                                                                
    */                                            
	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:kOrangeredErrorNotificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		NSLog(@"Responding to error: %@", orangeredError);
		if (orangeredError) {
			UIAlertView *orangeredErrorAlert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:[NSString stringWithFormat:@"%@", [orangeredError localizedDescription]] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[orangeredErrorAlert show];

			orangeredError = nil;
		}
	}];
    
    /*
	                                                                              /$$$$$$ 
	                                                                             /$$__  $$
	  /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$         /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__/
	 /$$__  $$ /$$__  $$ /$$__  $$| $$__  $$       /$$__  $$ /$$__  $$ /$$__  $$| $$$$    
	| $$  \ $$| $$  \ $$| $$$$$$$$| $$  \ $$      | $$  \ $$| $$  \__/| $$$$$$$$| $$_/    
	| $$  | $$| $$  | $$| $$_____/| $$  | $$      | $$  | $$| $$      | $$_____/| $$      
	|  $$$$$$/| $$$$$$$/|  $$$$$$$| $$  | $$      | $$$$$$$/| $$      |  $$$$$$$| $$      
	 \______/ | $$____/  \_______/|__/  |__/      | $$____/ |__/       \_______/|__/      
	          | $$                                | $$                                    
	          | $$                                | $$                                    
	          |__/                                |__/       
	*/                             
	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:kOrangeredOpenPrefsNotificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		[[UIApplication sharedApplication] openURL:[ORAlertViewDelegate sharedLaunchPreferencesURL]];
	}];

	/*
		       /$$                           /$$      
	          | $$                          | $$      
	  /$$$$$$$| $$$$$$$   /$$$$$$   /$$$$$$$| $$   /$$
	 /$$_____/| $$__  $$ /$$__  $$ /$$_____/| $$  /$$/
	| $$      | $$  \ $$| $$$$$$$$| $$      | $$$$$$/ 
	| $$      | $$  | $$| $$_____/| $$      | $$_  $$ 
	|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$| $$ \  $$
	 \_______/|__/  |__/ \_______/ \_______/|__/  \__/
	                                                  
	                                                  
    */                                           
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:kOrangeredCheckNotificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
    	OrangeredProvider *notificationProvider = [OrangeredProvider sharedInstance];
		NSString *sectionIdentifier = [notificationProvider sectionIdentifier];
		NSString *clientIdentifier = [orangeredPreferences objectForKey:@"clientIdentifier" default:nil];

    	// Let's cancel our appointments...
    	[orangeredTimer invalidate];
		orangeredSetDisplayIdentifierBadge(clientIdentifier, 0);

		if (previousClientIdentifier && ![previousClientIdentifier isEqualToString:clientIdentifier]) {
			orangeredSetDisplayIdentifierBadge(previousClientIdentifier, 0);
		}

		previousClientIdentifier = clientIdentifier;

    	// Load some preferences...
		BOOL enabled = [orangeredPreferences boolForKey:@"enabled" default:YES];
		if (!enabled) {
			return;
		}

		// I don't think this is needed anymore...but I haven't thoroughly tested it's removal yet.
//		// If there's a saved client identifier, which is different from the current identifier,
//		// and an app with that identifier is installed, then swap out the data provider so it
//		// uses the correct section identifier.
//		if (clientIdentifier &&
//			![clientIdentifier isEqualToString:sectionIdentifier] &&
//			[(SBApplicationController *)[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:clientIdentifier]) {
//			ORLOG(@"Detected change in app, swapping around data providers...");
//
//			[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];
//			notificationProvider.customSectionID = sectionIdentifier = clientIdentifier;
//		}
//
//		// If the current clientIdentifier doesn't have an app associated with it, revert back
//		// to a random check.
//		if (![(SBApplicationController *)[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:sectionIdentifier]) {
//			ORLOG(@"Detected bonkers app, reassigning data providers...");
//
//			notificationProvider.customSectionID = nil;
//		}

		CGFloat intervalUnit = [orangeredPreferences floatForKey:@"intervalControl" default:60.0];

		if (intervalUnit > 0.0) {
			NSString *refreshIntervalString = [orangeredPreferences objectForKey:@"refreshInterval" default:@"60"];
			CGFloat refreshInterval = [refreshIntervalString floatValue] * intervalUnit;

			orangeredTimer = [[PCSimpleTimer alloc] initWithTimeInterval:refreshInterval serviceIdentifier:@"com.insanj.orangered" target:notificationProvider selector:@selector(fireAway) userInfo:nil];
			[orangeredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];

			ORLOG(@"Spun up timer (%@) to ping Reddit every %f seconds.", orangeredTimer, refreshInterval);
		}

		else if ([notification.userInfo[@"sender"] isEqualToString:@"SpringBoard"]) {
			ORLOG(@"Appears our interval is set for Never, and pinging from Reddit. Killing time!");
			return;
		}

		else {
			ORLOG(@"Appears our interval is set for Never. Sulking time... :/");
		}

		CGFloat rateGuard = [orangeredPreferences floatForKey:@"rateGuard" default:0];
		if (rateGuard) {
			NSTimeInterval currentRequestInterval = [[NSDate date] timeIntervalSince1970];

			if (lastRequestInterval <= 0.0) {
				[orangeredPreferences setFloat:currentRequestInterval forKey:@"lastRequestStamp"];
				lastRequestInterval = [orangeredPreferences floatForKey:@"lastRequestStamp" default:currentRequestInterval];
			}

			if (currentRequestInterval - lastRequestInterval < 3.0) { // "Make no more than thirty requests per minute." with a little bit of leeway 
				ORLOG(@"Rate limit says YOU SHALL NOT PASS (last request interval: %f, current request interval: %f).", lastRequestInterval, currentRequestInterval);
				return;		
			}

			else {
				ORLOG(@"Rate limit is letting this one slide (last request interval: %f, current request interval: %f).", lastRequestInterval, currentRequestInterval);
			}

			lastRequestInterval = currentRequestInterval;
		}

		NSString *username = [orangeredPreferences objectForKey:@"username" default:@""];
		NSString *passwordKey = [orangeredPreferences objectForKey:@"password" default:@""];

		username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		passwordKey = [passwordKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	    // Apparently RedditKit crashes out if either are nil? Bizarre.
	    if ([username length] == 0 || [passwordKey length] == 0) {
	    	[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

			BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
			bulletin.recordID = @"com.insanj.orangered.bulletin";
			CFUUIDRef uuidRef = CFUUIDCreate(NULL);
			CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
			CFRelease(uuidRef);
			bulletin.bulletinID = (__bridge_transfer NSString *)uuidStringRef;
			bulletin.title = @"Orangered";
			bulletin.message = @"Uh-oh! Please check your username and password in the settings.";
			bulletin.sectionID = @"com.insanj.orangered";
			bulletin.date = [NSDate date];

			bulletin.defaultAction = [BBAction actionWithLaunchURL:[ORAlertViewDelegate sharedLaunchPreferencesURL] callblock:nil];
			orangeredAddBulletin(orangeredServer, notificationProvider, bulletin);
			return;
	    }

		BOOL repeatNotify = [orangeredPreferences boolForKey:@"repeatNotify" default:YES];
		BOOL alwaysNotify = [orangeredPreferences boolForKey:@"alwaysNotify" default:YES];
		BOOL alwaysMarkRead = [orangeredPreferences boolForKey:@"alwaysMarkRead" default:NO];
		BOOL securePassword = [orangeredPreferences boolForKey:@"secure" default:YES];
		BOOL combineMessages = [orangeredPreferences boolForKey:@"combineMessages" default:YES];
		BOOL useMessageTimeStamp = [orangeredPreferences boolForKey:@"useMessageTimeStamp" default:YES];

		NSString *password;
		if (securePassword) {
			// Let's get the real password, now that we've covered all the bases...
			NSError *getItemForKeyError;
			password = [FDKeychain itemForKey:passwordKey forService:@"Orangered" error:&getItemForKeyError];
			if (getItemForKeyError.code == -25308) {
				NSLog(@"Error trying to retrieve secured password, postponing until we're not at the lockscreen...");
				checkOnUnlock = YES;
				return;
			}

			else if (getItemForKeyError.code == -25300) {
				// NSLog(@"Error trying to retrieve secured password, have to secure it: %@", getItemForKeyError);
				password = [NSString stringWithString:passwordKey];
				NSMutableString *mutableKey = [[NSMutableString alloc] init];

			    for (int i = 0; i < password.length; i++) {
			        [mutableKey appendFormat:@"%c", arc4random_uniform(26) + 'a'];
			    }

				NSError *saveItemForKeyError;
				[FDKeychain saveItem:password forKey:mutableKey forService:@"Orangered" inAccessGroup:nil withAccessibility:FDKeychainAccessibleAfterFirstUnlock error:&saveItemForKeyError];
				if (saveItemForKeyError) {
					NSLog(@"Error trying to secure password: %@", saveItemForKeyError);
					return;
				}

				else {
					ORLOG(@"Secured password successfully! :)");
					[orangeredPreferences setObject:mutableKey forKey:@"password"];
				}
			}

			else if (getItemForKeyError) {
				NSLog(@"Fatal error trying to retrieve secure password: %@", getItemForKeyError);
		    	[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

				BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
				bulletin.recordID = @"com.insanj.orangered.bulletin";
				CFUUIDRef uuidRef = CFUUIDCreate(NULL);
				CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
				CFRelease(uuidRef);
				bulletin.bulletinID = (__bridge_transfer NSString *)uuidStringRef;
				bulletin.title = @"Orangered";
				bulletin.message = [NSString stringWithFormat:@"Had trouble securing your password. Fix to authenticate: %@", getItemForKeyError];
				bulletin.sectionID = @"com.insanj.orangered";
				bulletin.date = [NSDate date];

				bulletin.defaultAction = [BBAction actionWithLaunchURL:[ORAlertViewDelegate sharedLaunchPreferencesURL] callblock:nil];
				orangeredAddBulletin(orangeredServer, notificationProvider, bulletin);
				return;
			}

			else {
				ORLOG(@"Accessed secured password successfully!");
			}
		}

		else {
			password = passwordKey;
		}

		RKClient *client = [RKClient sharedClient];
		RKListingCompletionBlock unreadCompletionBlock = ^(NSArray *messages, RKPagination *pagination, NSError *error) {
			if (![orangeredPreferences boolForKey:@"disableNetworkIndicator" default:NO]) {
				[[UIApplication sharedApplication] _endShowingNetworkActivityIndicator];
			}
	    	ORLOG(@"Received unreadMessages response from Reddit: %@", messages);

			if (alwaysMarkRead && [messages count] > 0) {
				ORLOG(@"Ensuring messages are all marked read...");
				[client markMessageArrayAsRead:messages completion:^(NSError *error) {
					ORLOG(@"%@ cleared out unread messages.", error ? [NSString stringWithFormat:@"Failed (%@). Wishing I", [error localizedDescription]] : @"Successfully");
				}];
			}

			OrangeredProvider *provider = [OrangeredProvider sharedInstance];
			orangeredSetDisplayIdentifierBadge(clientIdentifier, messages.count);

			if (messages && messages.count > 0) {
				RKMessage *message = messages[0];

				if (!repeatNotify && lastMessageDate && [lastMessageDate compare:message.created] != NSOrderedAscending) {
					ORLOG(@"Not publishing duplicate bulletin request (current message date '%@' is equal to or earlier than previous message date '%@').", message.created, lastMessageDate);

					if (previousUnreadMessages) {
						// Previous Notification Center items exist. Loop through current list of unread messages so we can remove previous NC items that are now marked as read
						NSMutableSet *currentUnreadMessages = [[NSMutableSet alloc] init];
						for (int i = [messages count] - 1; i >= 0; i--) {
							RKMessage *message = messages[i];
							NSString *publisherBulletinID = [NSString stringWithFormat:@"com.insanj.orangered.bulletin/%@/%@", [orangeredDateFormatter stringFromDate:message.created], message.author];
							[currentUnreadMessages addObject:publisherBulletinID];
						}

						if (previousUnreadMessages && [currentUnreadMessages count] > 0) {
							[previousUnreadMessages minusSet:currentUnreadMessages];

							for (NSString *publisherID in previousUnreadMessages) {
								[orangeredServer withdrawBulletinRequestsWithPublisherBulletinID:publisherID forSectionID:sectionIdentifier];
							}
						} else if (previousUnreadMessages) {
							[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];
						}

						previousUnreadMessages = currentUnreadMessages;
					}
				}

				else {
					BOOL isRingerMuted = [[%c(SBMediaController) sharedInstance] isRingerMuted];
					BBSound *savedSound = nil;
					NSString *ringtoneIdentifier = [orangeredPreferences objectForKey:@"alertTone" default:nil];
					if (ringtoneIdentifier && ![ringtoneIdentifier isEqualToString:@"<none>"]) {
						NSString *ringtonePath;
						if (isRingerMuted) {
							ringtonePath = @"/Library/PreferenceBundles/ORPrefs.bundle/silent.caf";
						} else {
							TLToneManager *manager = [%c(TLToneManager) sharedToneManager];
							ringtonePath = [manager filePathForToneIdentifier:ringtoneIdentifier];
						}

						savedSound = [[BBSound alloc] initWithSystemSoundID:0 soundPath:ringtonePath behavior:1 vibrationPattern:nil];
						ORLOG(@"Assigning saved sound %@ to ringtone %@ to play...", ringtoneIdentifier, savedSound);
					}

					NSMutableSet *currentUnreadMessages = [[NSMutableSet alloc] init];
					// Reverse through the array so the oldest messages get added first
					for (int i = [messages count] - 1; i >= 0; i--) {
						RKMessage *message = messages[i];
						NSString *publisherBulletinID = [NSString stringWithFormat:@"com.insanj.orangered.bulletin/%@/%@", [orangeredDateFormatter stringFromDate:message.created], message.author];

						[currentUnreadMessages addObject:publisherBulletinID];
						if (!repeatNotify && previousUnreadMessages && [previousUnreadMessages containsObject:publisherBulletinID]) {
							ORLOG(@"Skipping already notified message %@", publisherBulletinID);
							continue;
						}

						BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
						bulletin.recordID = @"com.insanj.orangered.bulletin";
						bulletin.publisherBulletinID = combineMessages ? @"com.insanj.orangered.bulletin" : publisherBulletinID;

						CFUUIDRef uuidRef = CFUUIDCreate(NULL);
						CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
						CFRelease(uuidRef);
						bulletin.bulletinID = (__bridge_transfer NSString *)uuidStringRef;
						bulletin.sectionID = @"com.insanj.orangered";

						if ([clientIdentifier isEqualToString:@"com.apple.mobilesafari"]) {
							bulletin.defaultAction = [BBAction actionWithLaunchURL:[NSURL URLWithString:@"https://www.reddit.com/message/inbox/"] callblock:nil];
						}

						else {
							bulletin.defaultAction = [BBAction actionWithLaunchBundleID:clientIdentifier callblock:nil];
						}

						if (useMessageTimeStamp) {
							bulletin.date = message.created;
						}

						else {
							bulletin.date = [NSDate date];
						}

						if (savedSound) {
							bulletin.sound = savedSound;
						}

						bulletin.showsUnreadIndicator = message.unread;

						if (!combineMessages || messages.count == 1) {
							bulletin.title = message.author;
							bulletin.subtitle = message.subject;
							bulletin.message = message.messageBody;
						}

						else {
							if (useMessageTimeStamp) {
								// Use the date of the newest message
								bulletin.date = lastMessageDate;
							}

							bulletin.title = @"Orangered";
							bulletin.message = [NSString stringWithFormat:@"You have %i unread messages.", (int)messages.count];
						}

						orangeredAddBulletin(orangeredServer, provider, bulletin);

						if (combineMessages) {
							break;
						}
					}

					if (!combineMessages && previousUnreadMessages && [currentUnreadMessages count] > 0) {
						// Always try to remove the bulletin used for combined messages
						[orangeredServer withdrawBulletinRequestsWithPublisherBulletinID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

						[previousUnreadMessages minusSet:currentUnreadMessages];

						for (NSString *publisherID in previousUnreadMessages) {
							[orangeredServer withdrawBulletinRequestsWithPublisherBulletinID:publisherID forSectionID:sectionIdentifier];
						}
					} else if (previousUnreadMessages || combineMessages) {
						[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];
					}

					previousUnreadMessages = currentUnreadMessages;
					lastMessageDate = message.created;
				}
			}

			else if (alwaysNotify) {
		    	[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

				BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
				bulletin.recordID = @"com.insanj.orangered.bulletin";
				CFUUIDRef uuidRef = CFUUIDCreate(NULL);
				CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
				CFRelease(uuidRef);
				bulletin.bulletinID = (__bridge_transfer NSString *)uuidStringRef;
				bulletin.title = @"Orangered";

				bulletin.sectionID = @"com.insanj.orangered";
				bulletin.date = [NSDate date];

				BOOL isRingerMuted = [[%c(SBMediaController) sharedInstance] isRingerMuted];
				BBSound *savedSound = nil;
				NSString *ringtoneIdentifier = [orangeredPreferences objectForKey:@"alertTone" default:nil];
				if (ringtoneIdentifier && ![ringtoneIdentifier isEqualToString:@"<none>"]) {
					NSString *ringtonePath;
					if (isRingerMuted) {
						ringtonePath = @"/Library/PreferenceBundles/ORPrefs.bundle/silent.caf";
					} else {
						TLToneManager *manager = [%c(TLToneManager) sharedToneManager];
						ringtonePath = [manager filePathForToneIdentifier:ringtoneIdentifier];
					}

					savedSound = [[BBSound alloc] initWithSystemSoundID:0 soundPath:ringtonePath behavior:1 vibrationPattern:nil];
					ORLOG(@"Assigning saved sound %@ to ringtone %@ to play...", ringtoneIdentifier, savedSound);
				}

				if (savedSound) {
					bulletin.sound = savedSound;
				}

				if ([clientIdentifier isEqualToString:@"com.apple.mobilesafari"]) {
					bulletin.defaultAction = [BBAction actionWithLaunchURL:[NSURL URLWithString:@"https://www.reddit.com/message/inbox/"] callblock:nil];
				}

				else {
					bulletin.defaultAction = [BBAction actionWithLaunchBundleID:clientIdentifier callblock:nil];
				}

				NSArray *phrases = @[@"Take a coffee break.", @"Relax.", @"Time to pick up that old ten-speed.", @"Reserve your cat facts.", @"Channel your zen.", @"Why stress?", @"Orange you glad I didn't say Orangered?", @"Let's chill.", @"Head over to 4chan.", @"Buy yourself a tweak.", @"Hey, don't blame me.", @"Orangered powering down.", @"Have a nice day!", @"Don't even trip."];
				bulletin.message = [phrases[arc4random_uniform(phrases.count)] stringByAppendingString:@" No new messages found."];

				orangeredAddBulletin(orangeredServer, notificationProvider, bulletin);

			}

			else {
				// When there are no new messages, remove all previous items from the Notification Center
				[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];
			}
		}; // end unreadCompletionBlock

		// Time to do some WERK
		if ([client isSignedIn] && (![client.currentUser.username isEqualToString:username])) {
			ORLOG(@"Detected user changed, signing out...");
			[client signOut];
		}

		if (![orangeredPreferences boolForKey:@"disableNetworkIndicator" default:NO]) {
			[[UIApplication sharedApplication] _beginShowingNetworkActivityIndicator];
		}

		if (![client isSignedIn]) {
			ORLOG(@"No existing user session detected, signing in...");

			// Sign in using RedditKit and supplied login information, and ping for unread messages.
	    	[client signInWithUsername:username password:password completion:^(NSError *error) {
	    		if (error) {
			    	[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

	    			ORLOG(@"Encountered error (%@, %@), pushing bulletin request...", error, error.userInfo);
		        	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
					bulletin.recordID = @"com.insanj.orangered.bulletin";
					CFUUIDRef uuidRef = CFUUIDCreate(NULL);
					CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
					CFRelease(uuidRef);
					bulletin.bulletinID = (__bridge_transfer NSString *)uuidStringRef;
					bulletin.title = @"Orangered";

					NSString *relevantMessage;
					switch ((int)error.code) {
						default:
							relevantMessage = [NSString stringWithFormat:@"Uh-oh! %@", [error localizedDescription]];
							break;
						case 203:
							 relevantMessage = [NSString stringWithFormat:@"Invalid credentials. Reddit can't log you in with that username or password."];
							 break;
						case 204:
							 relevantMessage = [NSString stringWithFormat:@"Reddit has rate limited your device. Wait before using Orangered again!"];
							 break;
						case -1009:
							 relevantMessage = [NSString stringWithFormat:@"Rats! Please check your internet connection and try again."];
							 break;
					}

					bulletin.message = relevantMessage;
					bulletin.sectionID = @"com.insanj.orangered";
					bulletin.date = [NSDate date];

					bulletin.defaultAction = [BBAction actionWithLaunchURL:[ORAlertViewDelegate sharedLaunchPreferencesURL] callblock:nil];

					orangeredError = error;
					orangeredAddBulletin(orangeredServer, notificationProvider, bulletin);
					if (![orangeredPreferences boolForKey:@"disableNetworkIndicator" default:NO]) {
						[[UIApplication sharedApplication] _endShowingNetworkActivityIndicator];
					}
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
