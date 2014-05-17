#import "Orangered.h"

@interface OrangeredForiOS7Listener : NSObject<LAListener>
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event;
+ (void)load;
@end

@implementation OrangeredForiOS7Listener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"OrangeredLoadPrefs" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"OrangeredClientRefresh" object:nil];
	
	if (event) {
		[event setHandled:YES];
	}
}

+ (void)load {
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.insanj.orangered.listener"];
}

@end