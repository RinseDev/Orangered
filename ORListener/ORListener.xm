#import <libactivator/libactivator.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <UIKit/UIKit.h>

@interface ORListener : NSObject <LAListener>
@end

@implementation ORListener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event{
	NSLog(@"[Orangered] Sending check message from Activator...");

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil];
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