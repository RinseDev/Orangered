#import <Preferences/PSListController.h>

@interface ORListController: PSListController
@end

@implementation ORListController

- (id)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ORPrefs" target:self] retain];
	}

	return _specifiers;
}

@end

