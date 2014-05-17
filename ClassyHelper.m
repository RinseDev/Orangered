#import "ClassyHelper.h"

@implementation ClassyHelper
+ (instancetype)sharedInstance {
	static dispatch_once_t once = nil;
	static id sharedInstance = nil;

	// This, as the name says, will only ever execute once (the first time this method is called)
	// so initialize our instance here
	dispatch_once(&once, ^{
		sharedInstance = [[self alloc] init];
	});

	// return the shared instance
	return sharedInstance;
}

@end
