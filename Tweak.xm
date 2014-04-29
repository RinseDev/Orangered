#include "RedditKit.h"
#include "ClassyHelper.mm"
//#include "RefreshReddit.m"

NSMutableDictionary *prefs;
NSTimer* timer;
NSString* username;
NSString* password;
NSString* redditClient;
int refreshInterval;
BOOL enabled;
BOOL alwaysNotify;
BOOL minutesInterval;
BOOL debug;
BOOL alwaysMarkRead;
BOOL showAsAlert;
RKClient *client = [[RKClient alloc] init];
RKPagination *pagination = [RKPagination paginationWithLimit:10];

@interface BBBulletinRequest : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *sectionID;
@end

@interface SBBulletinBannerController : NSObject
+ (SBBulletinBannerController *)sharedInstance;
- (void)observer:(id)observer addBulletin:(BBBulletinRequest *)bulletin forFeed:(int)feed;
@end

@interface RKClient (Refresh) {}

-(void)refresh;

@end

@implementation RKClient (Refresh)

-(void)refresh {

	//RKClient *client = [[RKClient alloc] init];
	//RKPagination *pagination = [RKPagination paginationWithLimit:10];

	[client signInWithUsername:username password:password completion:^(NSError *error) {
    	if (!error) {
    		if (debug) NSLog(@"Orangered--Successfully signed in!");

			[client unreadMessagesWithPagination:pagination markRead:alwaysMarkRead completion:^(NSArray *messages, RKPagination *pagination, NSError *error) {

    				RKMessage* messageContent = [[RKMessage alloc] init];
    				messageContent = [messages firstObject];
    				if (debug) NSLog(@"Orangered--%@", [messageContent description]);
    				if (messageContent != nil) {
    					if (debug) NSLog(@"Orangered--%@", [messageContent messageBody]);
    					if (showAsAlert) {
                        	UIAlertView* newMessage = [[UIAlertView alloc] initWithTitle:@"Orangered" message:[NSString stringWithFormat:@"%@ \n%@", [messageContent author], [messageContent messageBody]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        	[newMessage show];
                        }

                        else if (!showAsAlert) {
                        	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
							request.title = [NSString stringWithFormat:@"Message from %@", [messageContent author]];
							request.message = [NSString stringWithFormat:@"%@", [messageContent messageBody]];
							request.sectionID = redditClient;
							[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
						}
					}

					else if (messageContent == nil) {

						if (alwaysNotify) {
							if (debug) NSLog(@"Orangered--No new messages--alwaysNotify");
							if (showAsAlert) {
                            	UIAlertView* noNewMessage = [[UIAlertView alloc] initWithTitle:@"Orangered" message:@"No Messages" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                            	[noNewMessage show];
                            }

                            else if (!showAsAlert) {
                            	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
								request.title = @"No Messages";
								request.message = @"Inbox empty";
								request.sectionID = redditClient;
								[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
							}
						}
						else if (!alwaysNotify) {
							if (debug) NSLog(@"Orangered--No new messages--!alwaysNotify");
						}
					}
    		}];

    	}
    	else if (error) {
    		if (debug) NSLog(@"Orangered--Error signing in");
    		if (showAsAlert) {
            	UIAlertView* errorLogInAlert = [[UIAlertView alloc] initWithTitle:@"Orangered Error" message:@"Error logging in. Please make sure your login information is correct and you have an active internet connection." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            	[errorLogInAlert show];
            }

            else if (!showAsAlert) {
            	BBBulletinRequest *request = [[BBBulletinRequest alloc] init];
				request.title = @"Orangered Error";
				request.message = @"Error logging in. Please make sure your login information is correct and you have an active internet connection.";
				request.sectionID = redditClient;
				[(SBBulletinBannerController *)[%c(SBBulletinBannerController) sharedInstance] observer:nil addBulletin:request forFeed:2];
            }
    	}
	}];

}

@end

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {

	%orig;
	if ([timer isValid]) [timer invalidate];
	timer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:client selector:@selector(refresh) userInfo:nil repeats:YES];
	if (debug) NSLog(@"Orangered--Started timer with %d interval on SB didFinishLaunching", refreshInterval);
}

%end

void loadPreferences () {

	prefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.phillipt.orangered.plist"]];

	if ([prefs objectForKey:@"enabled"] == nil) enabled = YES;
	else if ([prefs objectForKey:@"enabled"] != nil) enabled = [[prefs objectForKey:@"enabled"] boolValue];

	if ([prefs objectForKey:@"username"] == nil) {
		UIAlertView* notLoggedInAlert = [[UIAlertView alloc] initWithTitle:@"Orangered Error" message:@"Error: No username provided." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[notLoggedInAlert show];
	}
	else if ([prefs objectForKey:@"username"] != nil) username = [prefs objectForKey:@"username"];

	if ([prefs objectForKey:@"password"] == nil) {
		UIAlertView* notLoggedInAlert = [[UIAlertView alloc] initWithTitle:@"Orangered Error" message:@"Error: No password provided." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
		[notLoggedInAlert show];
	}
	else if ([prefs objectForKey:@"password"] != nil) password = [prefs objectForKey:@"password"];

	if ([prefs objectForKey:@"alwaysNotify"] == nil) alwaysNotify = YES;
	else if ([prefs objectForKey:@"alwaysNotify"] != nil) alwaysNotify = [[prefs objectForKey:@"alwaysNotify"] boolValue];

	if ([prefs objectForKey:@"minutesInterval"] == nil) minutesInterval = YES;
	else if ([prefs objectForKey:@"minutesInterval"] != nil) minutesInterval = [[prefs objectForKey:@"minutesInterval"] boolValue];

	if ([prefs objectForKey:@"showAsAlert"] == nil) showAsAlert = NO;
	else if ([prefs objectForKey:@"showAsAlert"] != nil) showAsAlert = [[prefs objectForKey:@"showAsAlert"] boolValue];

	if ([prefs objectForKey:@"refreshInterval"] == nil) {

		if (minutesInterval) {
			refreshInterval = 60 * 60;
		}

		else if (!minutesInterval) {
			refreshInterval = 60 * 60 * 60;
		}

	}
	else if ([prefs objectForKey:@"refreshInterval"] != nil) {

		if (minutesInterval) {
			refreshInterval = [[prefs objectForKey:@"refreshInterval"] intValue] * 60;
		}

		else if (!minutesInterval) {
			refreshInterval = [[prefs objectForKey:@"refreshInterval"] intValue] * 60 * 60;
		}

		refreshInterval = [[prefs objectForKey:@"refreshInterval"] intValue];
	}

	if ([prefs objectForKey:@"debug"] == nil) debug = NO;
	else if ([prefs objectForKey:@"debug"] != nil) debug = [[prefs objectForKey:@"debug"] boolValue];

	if ([prefs objectForKey:@"alwaysMarkRead"] == nil) alwaysMarkRead = NO;
	else if ([prefs objectForKey:@"alwaysMarkRead"] != nil) alwaysMarkRead = [[prefs objectForKey:@"alwaysMarkRead"] boolValue];

	if ([prefs objectForKey:@"redditClient"] == nil) redditClient = @"libactivator";
	else if ([prefs objectForKey:@"redditClient"] != nil) {

		if ([[prefs objectForKey:@"redditClient"] isEqual:@"alienblue"]) redditClient = @"com.designshed.alienblue";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"aliens"]) redditClient = @"com.appseedinc.aliens";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"amrc"]) redditClient = @"com.amleszk.amrc";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"baconreader"]) redditClient = @"com.onelouder.BaconReader";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"ialien"]) redditClient = @"com.jinsongniu.ialiengallery";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"karma"]) redditClient = @"com.mediaspree.karma";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"karmatrain"]) redditClient = @"com.lm.karmatrain";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"picshdforreddit"]) redditClient = @"com.funpokesinc.redditpics";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"redditpicspro"]) redditClient = @"reddit.pics.pro";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"reddito"]) redditClient = @"com.alexiscreuzot.reddito";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"redditor"]) redditClient = @"com.tyanya.reddit";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"upvote"]) redditClient = @"com.nicholasleedesigns.upvote";
		else if ([[prefs objectForKey:@"redditClient"] isEqual:@"other"]) redditClient = @"libactivator";
		else redditClient = @"libactivator";

	}

	if([timer isValid]) [timer invalidate];
    if (enabled) {
    	timer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:client selector:@selector(refresh) userInfo:nil repeats:YES];
    	if (debug) NSLog(@"Orangered--Started timer with %d interval on loadPrefs", refreshInterval);
    }

    else if (!enabled) {
    	[timer invalidate];
    }

	if (debug) NSLog(@"Orangered--%@", [prefs description]);

}

%ctor {

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
									NULL,
									(CFNotificationCallback)loadPreferences,
									CFSTR("com.phillipt.orangered/preferencechanged"),
									NULL,
									CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPreferences();

	%init();

}
