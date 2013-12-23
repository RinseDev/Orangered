#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import "../ORLogger.h"

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

@interface ORListener : NSObject <LAListener>
@end

@implementation ORListener

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	[ORLogger log:@"received Activator action, about to check (if all clears)..." fromSource:@"ORListener.xm"];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]];
	NSString *savedName = [settings objectForKey:@"usernameText"];
	NSString *savedPass = [settings objectForKey:@"passwordText"];

	if (!savedName || [savedName isEmpty] || !savedPass || [savedPass isEmpty]){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"You need a valid Reddit username and password to use Orangered!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
		return;
	}//end if not user/pass

	NSDictionary *sentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Orangered", @"title", @"checking for new messages...", @"message", @"wait", @"label", [NSNumber numberWithBool:YES], @"show", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ORGivenNotification" object:nil userInfo:sentDictionary];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ORPullNotification" object:nil];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	//air
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	//air
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	//air
}

- (void)dealloc {
	[super dealloc];
}

+ (void)load {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"libactivator.ORListener"];
	[pool release];
}

@end 