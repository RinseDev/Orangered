#import "Orangered.h"

#define RANDOM_PHRASE(str) [@[@"Take a coffee break.", @"Relax.", @"Time to pick up that old ten-speed.", @"Reserve your cat facts.", @"Channel your zen.", @"Why stress?", @"Orange you glad I didn't say Orangered?", @"Let's chill."][arc4random_uniform(8)] stringByAppendingString:str];

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

@interface OrangeredChecker : NSObject
- (void)fireAway;
@end

@implementation OrangeredChecker

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
		NSDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.insanj.orangered.plist"];

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

    	orangeredTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:[OrangeredChecker new] selector:@selector(fireAway) userInfo:nil repeats:NO];

	    // Set-up some variables...
		RKClient *client = [[RKClient alloc] init];
		RKPagination *pagination = [RKPagination paginationWithLimit:10];

    	// Sign in using RedditKit and supplied login information (retrieved earlier, presumably)...
    	[client signInWithUsername:username password:password completion:^(NSError *error) {
    		if (error) {
	        	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
				request.title = @"Orangered";
				request.message = [@"Oops! Looks like there was a problem logging you in. Please make sure your login information is correct and you have an active internet connection. Error: " stringByAppendingString:[error localizedDescription]];
				request.sectionID = @"com.apple.Preferences";
				[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
				return;
    		}

			// If properly signed in, check for unread messages...			
			[client unreadMessagesWithPagination:pagination markRead:alwaysMarkRead completion:^(NSArray *messages, RKPagination *pagination, NSError *error) {
				RKMessage *messageContent = [messages firstObject];

				if (messageContent) {					
                	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
					request.title = [NSString stringWithFormat:@"%@ from %@", messageContent.subject, messageContent.author];
					request.message = [messageContent messageBody];
					request.sectionID = orangeredClientIdentifier();

					[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
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
    }];
}
