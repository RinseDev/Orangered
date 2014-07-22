#import <libactivator/libactivator.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <UIKit/UIKit.h>

// #define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define ORLOG(fmt, ...) 

@interface ORListener : NSObject <LAListener>
@end

@implementation ORListener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event{
	ORLOG(@"[Orangered] Sending check message from Activator...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil userInfo:@{ @"sender" : @"Activator" }];
	[event setHandled:YES];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event{
	// air
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event{
	// air
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event{
	// air
}

- (void)dealloc{
	[super dealloc];
}

+(void)load{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.insanj.orangered.listener"];
	[pool release];
}
@end 