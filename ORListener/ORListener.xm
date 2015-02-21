#import "ORListener.h"

@implementation ORListener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	ORLOG(@"[Orangered] Sending check message from Activator...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil userInfo:@{ @"sender" : @"Activator" }];
	[event setHandled:YES];
}

+ (void)load {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.insanj.orangered.listener"];
	[pool release];
}

@end 