#import <Preferences/Preferences.h>

@interface OrangeredForiOS7ListController: PSListController {
}
@end

@implementation OrangeredForiOS7ListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"OrangeredForiOS7" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
