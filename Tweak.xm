#import "Orangered.h"

// TODO: Really not cool, have to fix in future...
NSMutableDictionary *prefs;
NSTimer *timer;
NSString *username, *password, *redditClient;
CGFloat refreshInterval;
BOOL enabled, alwaysNotify, minutesInterval, alwaysMarkRead;

RKClient *client;
RKPagination *pagination;

@implementation RKClient (Refresh)

- (void)refresh {
	[client signInWithUsername:username password:password completion:^(NSError *error) {
		if (!error) {
			ORLOG(@"signed in!");
			[client unreadMessagesWithPagination:pagination markRead:alwaysMarkRead completion:^(NSArray *messages, RKPagination *pagination, NSError *error) {
				RKMessage *messageContent = [messages firstObject];
				ORLOG(@"%@" messageContent);

				if (messageContent) {
					ORLOG(@"body: %@", messageContent.body);
					
                	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
					request.title = [NSString stringWithFormat:@"Message from %@", [messageContent author]];
					request.message = [NSString stringWithFormat:@"%@", [messageContent messageBody]];
					request.sectionID = redditClient;

					[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
				}

				else {
					ORLOG(@"no new messages, %@" ? alwaysNotify ? @"notify" : @"don't notify");
					if (alwaysNotify) {
                    	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
						request.title = @"No Messages";
						request.message = @"Inbox empty";
						request.sectionID = redditClient;
						[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
					}
				}
    		}];

    	}

    	else {
			ORLOG(@"didn't signed in: %@", error);
        	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
			request.title = @"Orangered Error";
			request.message = @"Error logging in. Please make sure your login information is correct and you have an active internet connection.";
			request.sectionID = redditClient;
			[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
    	}
	}];
}

@end

static void loadOrangeredPreferences (){
	prefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]];
	ORLOG(@"%@", prefs);

	enabled = !prefs[@"enabled"] || [prefs[@"enabled"] boolValue];
	username = prefs[@"username"];
	password = prefs[@"password"];
	alwaysNotify = !prefs[@"alwaysNotify"] || [prefs[@"alwaysNotify"] boolValue];
	minutesInterval = !prefs[@"minutesInterval"] || [prefs[@"minutesInterval"] boolValue];
	alwaysMarkRead = prefs[@"alwaysMarkRead"] && [prefs[@"alwaysMarkRead"] boolValue];

	NSString *refreshIntervalString = prefs[@"refreshInterval"];
	if (refreshIntervalString) {
		refreshInterval = minutesInterval ? [refreshIntervalString floatValue] : [refreshIntervalString floatValue] * 60.0;
	}

	else {
		refreshInterval = minutesInterval ? 3600.0 : 216000.0;
	}

	NSString *thingsNotProvided = @"";
	if (!username) {
		thingsNotProvided = [NSString stringWithFormat:@"%@, %@", thingsNotProvided, username];
	}

	if (!password) {
		thingsNotProvided = [NSString stringWithFormat:@"%@, %@", thingsNotProvided, password];
	}

	UIAlertView *urgentAlert = [[UIAlertView alloc] initWithTitle:@"Orangered" message:[NSString stringWithFormat:@"Oops! Looks like a valid %@ wasn't provided. Check your Settings before Orangered is activated again to resolve this issue!", thingsNotProvided] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[urgentAlert show];

	if ([timer isValid]) {
		[timer invalidate];
	}
   
    if (enabled) {
    	timer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:client selector:@selector(refresh) userInfo:nil repeats:YES];
    	ORLOG(@"started timer with %d interval on loadPrefs", refreshInterval);
    }

    else {
    	[timer invalidate];
    }
}

%ctor {
	client = [[RKClient alloc] init];
	pagination = [RKPagination paginationWithLimit:10];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&loadOrangeredPreferences, CFSTR("com.insanj.orangered/preferencechanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"OrangeredLoadPrefs" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
    	loadOrangeredPreferences();
    }];

    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"OrangeredClientRefresh" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
    	[client refresh];
    }];


	loadOrangeredPreferences();

	timer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:client selector:@selector(refresh) userInfo:nil repeats:YES];
}
