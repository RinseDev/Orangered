#import "Orangered.h"
#import "ORProviders.h"
#import "External/AFNetworking.h"
#import "External/RedditKit.h"
#import "External/Mantle.h"
#import "External/FDKeychain.h"

@interface SBIconModel (Orangered7)
- (id)applicationIconForDisplayIdentifier:(id)arg1;
@end

@interface SBIconModel (Orangered8)
- (id)applicationIconForBundleIdentifier:(id)arg1;
@end

@interface SBApplicationController (Orangered8)
- (id)applicationWithBundleIdentifier:(id)arg1;
@end

/*                                                                                                                                                  
           /$$                       /$$             /$$                        
          | $$                      | $$            |__/                        
  /$$$$$$ | $$  /$$$$$$   /$$$$$$  /$$$$$$ /$$    /$$/$$  /$$$$$$  /$$  /$$  /$$
 |____  $$| $$ /$$__  $$ /$$__  $$|_  $$_/|  $$  /$$/ $$ /$$__  $$| $$ | $$ | $$
  /$$$$$$$| $$| $$$$$$$$| $$  \__/  | $$   \  $$/$$/| $$| $$$$$$$$| $$ | $$ | $$
 /$$__  $$| $$| $$_____/| $$        | $$ /$$\  $$$/ | $$| $$_____/| $$ | $$ | $$
|  $$$$$$$| $$|  $$$$$$$| $$        |  $$$$/ \  $/  | $$|  $$$$$$$|  $$$$$/$$$$/
 \_______/|__/ \_______/|__/         \___/    \_/   |__/ \_______/ \_____/\___/ 
                                                                                
*/

@interface ORAlertViewDelegate : NSObject <UIAlertViewDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
+ (NSURL *)sharedLaunchPreferencesURL;
@end

@implementation ORAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
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
                                                                                      
  /$$$$$$                               /$$     /$$                              
 /$$__  $$                             | $$    |__/                              
| $$  \__/$$   /$$ /$$$$$$$   /$$$$$$$/$$$$$$   /$$  /$$$$$$  /$$$$$$$   /$$$$$$$
| $$$$  | $$  | $$| $$__  $$ /$$_____/_  $$_/  | $$ /$$__  $$| $$__  $$ /$$_____/
| $$_/  | $$  | $$| $$  \ $$| $$       | $$    | $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$    | $$  | $$| $$  | $$| $$       | $$ /$$| $$| $$  | $$| $$  | $$ \____  $$
| $$    |  $$$$$$/| $$  | $$|  $$$$$$$ |  $$$$/| $$|  $$$$$$/| $$  | $$ /$$$$$$$/
|__/     \______/ |__/  |__/ \_______/  \___/  |__/ \______/ |__/  |__/|_______/ 
                                                                                                                                                               
*/

static ORAlertViewDelegate *orangeredAlertDelegate;
static PCPersistentTimer *orangeredTimer;
static NSError *orangeredError;
static BOOL checkOnUnlock;
static NSTimeInterval lastRequestInterval;
static BBBulletinRequest *lastBulletin;

static NSString * orangeredPhrase() {
	NSArray *phrases = @[@"Take a coffee break.", @"Relax.", @"Time to pick up that old ten-speed.", @"Reserve your cat facts.", @"Channel your zen.", @"Why stress?", @"Orange you glad I didn't say Orangered?", @"Let's chill.", @"Head over to 4chan.", @"Buy yourself a tweak.", @"Hey, don't blame me.", @"Orangered powering down.", @"Have a nice day!", @"Don't even trip."];
	return [phrases[arc4random_uniform(phrases.count)] stringByAppendingString:@" No new messages found."];
}

static void orangeredSetDisplayIdentifierBadge(NSString *displayIdentifier, NSInteger badgeValue) {
	SBIconModel *iconModel = MSHookIvar<SBIconModel *>([%c(SBIconController) sharedInstance], "_iconModel");
	NSString *stringBadgeValue;
	if (badgeValue > 0)  {
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
		[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		stringBadgeValue = [formatter stringForObjectValue:@(badgeValue)];
	}

	SBApplicationIcon *clientAppIcon = IOS_8 ? [iconModel applicationIconForBundleIdentifier:displayIdentifier] : [iconModel applicationIconForDisplayIdentifier:displayIdentifier]; 
	[clientAppIcon setBadge:stringBadgeValue];

	ORLOG(@"set badge %@ to %@", stringBadgeValue, clientAppIcon);
}

static void orangeredAddBulletin(BBServer *server, OrangeredProvider *provider, BBBulletinRequest *bulletin) {
	if (IOS_8) {
		[server _addBulletin:bulletin];
	}

	else {
		BBDataProviderAddBulletin(provider, bulletin);
	}
}

/*

                               /$$                     /$$                                         /$$
                              |__/                    | $$                                        | $$
  /$$$$$$$  /$$$$$$   /$$$$$$  /$$ /$$$$$$$   /$$$$$$ | $$$$$$$   /$$$$$$  /$$$$$$   /$$$$$$  /$$$$$$$
 /$$_____/ /$$__  $$ /$$__  $$| $$| $$__  $$ /$$__  $$| $$__  $$ /$$__  $$|____  $$ /$$__  $$/$$__  $$
|  $$$$$$ | $$  \ $$| $$  \__/| $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$ /$$$$$$$| $$  \__/ $$  | $$
 \____  $$| $$  | $$| $$      | $$| $$  | $$| $$  | $$| $$  | $$| $$  | $$/$$__  $$| $$     | $$  | $$
 /$$$$$$$/| $$$$$$$/| $$      | $$| $$  | $$|  $$$$$$$| $$$$$$$/|  $$$$$$/  $$$$$$$| $$     |  $$$$$$$
|_______/ | $$____/ |__/      |__/|__/  |__/ \____  $$|_______/  \______/ \_______/|__/      \_______/
          | $$                               /$$  \ $$                                                
          | $$                              |  $$$$$$/                                                
          |__/                               \______/                                                 

*/

%group SpringBoard

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
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil userInfo:@{ @"sender" : @"SpringBoard" }];
	}
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig();

	ORLOG(@"Sending check message from SpringBoard...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil userInfo:@{ @"sender" : @"SpringBoard" }];
}

%end

/*

 /$$       /$$                                                                 
| $$      | $$                                                                 
| $$$$$$$ | $$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$  /$$    /$$/$$$$$$   /$$$$$$ 
| $$__  $$| $$__  $$ /$$_____/ /$$__  $$ /$$__  $$|  $$  /$$/$$__  $$ /$$__  $$
| $$  \ $$| $$  \ $$|  $$$$$$ | $$$$$$$$| $$  \__/ \  $$/$$/ $$$$$$$$| $$  \__/
| $$  | $$| $$  | $$ \____  $$| $$_____/| $$        \  $$$/| $$_____/| $$      
| $$$$$$$/| $$$$$$$/ /$$$$$$$/|  $$$$$$$| $$         \  $/ |  $$$$$$$| $$      
|_______/ |_______/ |_______/  \_______/|__/          \_/   \_______/|__/      
                                                                               
*/

static BBServer *orangeredServer;

%hook BBServer

- (id)init {
	orangeredServer = %orig();
	OrangeredProvider *sharedProvider = [OrangeredProvider sharedInstance];

	if (IOS_8) {
		[orangeredServer _addActiveSectionID:[sharedProvider sectionIdentifier]];
	}

	else {
		[orangeredServer _addDataProvider:sharedProvider forFactory:sharedProvider.factory];
	}

	return orangeredServer;
}

%end

%end // %group SpringBoard

/*
                               /$$$$$$        
                              /$$__  $$       
  /$$$$$$   /$$$$$$  /$$$$$$ | $$  \__/$$$$$$$
 /$$__  $$ /$$__  $$/$$__  $$| $$$$  /$$_____/
| $$  \ $$| $$  \__/ $$$$$$$$| $$_/ |  $$$$$$ 
| $$  | $$| $$     | $$_____/| $$    \____  $$
| $$$$$$$/| $$     |  $$$$$$$| $$    /$$$$$$$/
| $$____/ |__/      \_______/|__/   |_______/ 
| $$                                          
| $$                                          
|__/  

*/

%group Preferences

%hook PreferencesAppController

-(void)applicationOpenURL:(NSURL *)arg1 {
	ORLOG(@"Heard openURL: %@", arg1);
	if ([arg1 isEqual:[ORAlertViewDelegate sharedLaunchPreferencesURL]]) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Error" object:nil];
	}

	return %orig();
}

%end

// Snatch up that notification center icon.
/*
%hook PSSpecifier

- (void)setProperty:(id)arg1 forKey:(NSString *)arg2 {
	%log;
	%orig();

	if ([arg1 isKindOfClass:[UIImage class]] && [arg2 isEqualToString:@"iconImage"] && [self.identifier isEqualToString:@"NOTIFICATIONS_ID"]) {
		UIImage *iconImage = (UIImage *)arg1; // 29x29
		CGSize retinaSize = CGSizeMake(iconImage.size.width * 2.0, iconImage.size.height * 2.0);
	    UIGraphicsBeginImageContextWithOptions(retinaSize, NO, iconImage.scale);
	    [iconImage drawInRect:(CGRect){CGPointZero, retinaSize}];
	    UIImage *retinaIconImage = UIGraphicsGetImageFromCurrentImageContext();    
	    UIGraphicsEndImageContext();

	    NSData *notificationCenterImageData = UIImagePNGRepresentation(retinaIconImage); 
		NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
		[preferences setObject:notificationCenterImageData forKey:@"notificationCenterImageData"];
		[preferences writeToFile:PREFS_PATH atomically:YES];

		//  orangeredSavedNotificationCenterIconImage = [notificationCenterImageData writeToFile:@"/Library/PreferenceBundles/ORPrefs.bundle/notificationcenter@2x.png" atomically:YES];
	}
}

%end*/

%end // %group Preferences

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
	// Because screw stupid class comparisons, they suck.
	NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier; // NSStringFromClass([UIApplication sharedApplication].class);
	ORLOG(@"Comparing %@ to detect proper injections...", bundleIdentifier);

	if ([bundleIdentifier isEqualToString:@"com.apple.Preferences"]) {
		ORLOG(@"Injecting Preferences hooks...");
		%init(Preferences);
		return;
	}

	else {
		ORLOG(@"Injecting SpringBoard hooks and registering listeners...");
		%init(SpringBoard);

		[[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.NotificationCenter" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
			NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PREFS_PATH];
			NSString *clientIdentifier = preferences[@"clientIdentifier"];
			NSURL *notificationCenterURL;
			if (clientIdentifier) {
				notificationCenterURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&path=%@", [%c(PSNotificationSettingsDetail) preferencesURL].absoluteString, clientIdentifier]];
			}

			else {
				notificationCenterURL = [%c(PSNotificationSettingsDetail) preferencesURL];
			}

			ORLOG(@"lol2 opening notificationCenterURL: %@", notificationCenterURL);
			[[UIApplication sharedApplication] openURL:notificationCenterURL];
		}];
	}

	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.Error" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		NSLog(@"Responding to error: %@", orangeredError);
		if (orangeredError) {
			UIAlertView *orangeredErrorAlert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:[NSString stringWithFormat:@"%@", orangeredError] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[orangeredErrorAlert show];

			orangeredError = nil;
		}
	}];
    	
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"Orangered.Check" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
    	OrangeredProvider *notificationProvider = [OrangeredProvider sharedInstance];
		NSString *sectionIdentifier = [notificationProvider sectionIdentifier];

    	// Let's cancel our appointments...
    	[orangeredTimer invalidate];
		orangeredSetDisplayIdentifierBadge(sectionIdentifier, 0);

    	// Load some preferences...
		NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];

		BOOL enabled = !preferences[@"enabled"] || [preferences[@"enabled"] boolValue];
		if (!enabled) {
			return;
		}

		NSString *clientIdentifier = preferences[@"clientIdentifier"];

		if (IOS_8) {
			// If there's a saved client identifier, which is different from the current identifier,
			// and an app with that identifier is installed, then swap out the data provider so it
			// uses the correct section identifier.
			if (clientIdentifier &&
				![clientIdentifier isEqualToString:sectionIdentifier] &&
				[(SBApplicationController *)[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:clientIdentifier]) {
				ORLOG(@"Detected change in app, swapping around data providers...");

				[orangeredServer _removeActiveSectionID:sectionIdentifier];
				notificationProvider.customSectionID = sectionIdentifier = clientIdentifier;
				[orangeredServer _addActiveSectionID:clientIdentifier];

			}

			// If the current clientIdentifier doesn't have an app associated with it, revert back
			// to a random check.
			if (![(SBApplicationController *)[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:sectionIdentifier]) {
				ORLOG(@"Detected bonkers app, reassigning data providers...");

				[orangeredServer _removeActiveSectionID:sectionIdentifier];
				notificationProvider.customSectionID = nil;
				[orangeredServer _addActiveSectionID:[notificationProvider sectionIdentifier]];

			}
		}

		else {
			// If there's a saved client identifier, which is different from the current identifier,
			// and an app with that identifier is installed, then swap out the data provider so it
			// uses the correct section identifier.
			if (clientIdentifier &&
				![clientIdentifier isEqualToString:sectionIdentifier] &&
				[(SBApplicationController *)[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:clientIdentifier]) {
				ORLOG(@"Detected change in app, swapping around data providers...");

				[orangeredServer _removeDataProvider:notificationProvider forFactory:notificationProvider.factory];
				notificationProvider.customSectionID = sectionIdentifier = clientIdentifier;
				[orangeredServer _addDataProvider:notificationProvider forFactory:notificationProvider.factory];
			}

			// If the current clientIdentifier doesn't have an app associated with it, revert back
			// to a random check.
			if (![(SBApplicationController *)[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:sectionIdentifier]) {
				ORLOG(@"Detected bonkers app, reassigning data providers...");

				[orangeredServer _removeDataProvider:notificationProvider forFactory:notificationProvider.factory];
				notificationProvider.customSectionID = nil;
				[orangeredServer _addDataProvider:notificationProvider forFactory:notificationProvider.factory];
			}
		}

		CGFloat intervalUnit = preferences[@"intervalControl"] ? [preferences[@"intervalControl"] floatValue] : 60.0;

		if (intervalUnit > 0.0) {
			NSString *refreshIntervalString = preferences[@"refreshInterval"];
			CGFloat refreshInterval = (refreshIntervalString ? [refreshIntervalString floatValue] : 60.0) * intervalUnit;

			orangeredTimer = [[PCPersistentTimer alloc] initWithTimeInterval:refreshInterval serviceIdentifier:@"com.insanj.orangered" target:notificationProvider selector:@selector(fireAway) userInfo:nil];
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

		NSNumber *rateGuard = preferences[@"rateGuard"];
		if (!rateGuard || [rateGuard boolValue]) {
			NSTimeInterval currentRequestInterval = [[NSDate date] timeIntervalSince1970];

			if (lastRequestInterval <= 0.0) {
				NSNumber *lastRequestStamp = preferences[@"lastRequestStamp"];
				[preferences setObject:@(currentRequestInterval) forKey:@"lastRequestStamp"];
				[preferences writeToFile:PREFS_PATH atomically:YES];

				if (!lastRequestStamp) {
					lastRequestInterval = currentRequestInterval;
				}

				else {
					lastRequestInterval = [lastRequestStamp floatValue];
				}
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

		NSString *username = preferences[@"username"] ?: @"";
		NSString *passwordKey = preferences[@"password"] ?: @"";

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
			bulletin.sectionID = @"com.apple.Preferences";
			bulletin.date = [NSDate date];

			bulletin.defaultAction = [BBAction actionWithLaunchURL:[ORAlertViewDelegate sharedLaunchPreferencesURL] callblock:nil];
			orangeredAddBulletin(orangeredServer, notificationProvider, bulletin);
			return;
	    }

		BOOL alwaysNotify = !preferences[@"alwaysNotify"] || [preferences[@"alwaysNotify"] boolValue];
		BOOL alwaysMarkRead = preferences[@"alwaysMarkRead"] && [preferences[@"alwaysMarkRead"] boolValue];
		
		BOOL securePassword = !preferences[@"secure"] || [preferences[@"secure"] boolValue];
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
				NSLog(@"Error trying to retrieve secured password, have to secure it: %@", getItemForKeyError);
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
					[preferences setObject:mutableKey forKey:@"password"];
					[preferences writeToFile:PREFS_PATH atomically:YES];
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
				bulletin.sectionID = @"com.apple.Preferences";
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

	    // Set-up some variables...
		RKClient *client = [RKClient sharedClient];
		RKListingCompletionBlock unreadCompletionBlock = ^(NSArray *messages, RKPagination *pagination, NSError *error) {
			[[UIApplication sharedApplication] _endShowingNetworkActivityIndicator];
	    	ORLOG(@"Received unreadMessages response from Reddit: %@", messages);

			if (alwaysMarkRead && [messages count] > 0) {
				ORLOG(@"Ensuring messages are all marked read...");
				[client markMessageArrayAsRead:messages completion:^(NSError *error) {
					ORLOG(@"%@ cleared out unread messages.", error ? [NSString stringWithFormat:@"Failed (%@). Wishing I", [error localizedDescription]] : @"Successfully");
				}];
			}

			OrangeredProvider *provider = [OrangeredProvider sharedInstance];
	    	NSString *sectionID = [provider sectionIdentifier];

	    	orangeredSetDisplayIdentifierBadge(sectionID, messages.count);
    		// BBDataProviderWithdrawBulletinsWithRecordID(provider, sectionID);
			// [server withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionID];

			if (messages && messages.count > 0) {	
            	BBBulletinRequest *bulletin = [[BBBulletinRequest alloc] init];
				bulletin.recordID = @"com.insanj.orangered.bulletin";
				CFUUIDRef uuidRef = CFUUIDCreate(NULL);
				CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
				CFRelease(uuidRef);
				bulletin.bulletinID = (__bridge_transfer NSString *)uuidStringRef;
				bulletin.sectionID = sectionID;
				bulletin.defaultAction = [BBAction actionWithLaunchBundleID:sectionID callblock:nil];
				bulletin.date = [NSDate date];

				NSString *ringtoneIdentifier = preferences[@"alertTone"];
				if (ringtoneIdentifier && ![ringtoneIdentifier isEqualToString:@"<none>"]) {
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

				// lastBulletin = (BBBulletin *)[(NSSet *)[orangeredServer _allBulletinsForSectionID] anyObject]

				if (lastBulletin && [lastBulletin.message isEqualToString:bulletin.message]) {
					ORLOG(@"Not publishing duplicate bulletin request (%@ equiv to %@).", bulletin, lastBulletin);
				}

				else {
			    	[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

					ORLOG(@"Publishing bulletin request (%@) to provider (%@). (not equiv in %@).", bulletin, provider, lastBulletin);
					orangeredAddBulletin(orangeredServer, provider, bulletin);

					lastBulletin = bulletin;
				}

				// [orangeredServer _publishBulletinRequest:bulletin forSectionID:sectionID forDestinations:2];
				// [orangeredServer publishBulletinRequest:bulletin destinations:2];

				// [provider pushBulletin:bulletin intoServer:orangeredServer];
				// BBDataProviderAddBulletin(provider, bulletin);
				// [server _publishBulletinRequest:bulletin forSectionID:sectionID forDestinations:2];
				// [(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
			}

			else if (alwaysNotify) {
		    	[orangeredServer withdrawBulletinRequestsWithRecordID:@"com.insanj.orangered.bulletin" forSectionID:sectionIdentifier];

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
					bulletin.sectionID = @"com.apple.Preferences";
					bulletin.date = [NSDate date];

					bulletin.defaultAction = [BBAction actionWithLaunchURL:[ORAlertViewDelegate sharedLaunchPreferencesURL] callblock:nil];

					orangeredError = error;
					orangeredAddBulletin(orangeredServer, notificationProvider, bulletin);
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
