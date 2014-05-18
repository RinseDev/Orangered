#import <Preferences/Preferences.h>
#import <Foundation/NSDistributedNotificationCenter.h>

@interface ORListController: PSListController
@end

@implementation ORListController

- (id)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ORPrefs" target:self] retain];
	}

	return _specifiers;
}

- (void)loadView {
	[super loadView];

	NSDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.insanj.orangered.plist"];
	if (![preferences objectForKey:@"intervalControl"]) {
		PSSpecifier *refreshControlSpecifier = [self specifierForID:@"IntervalControl"];
		[self setPreferenceValue:@(60.0) specifier:refreshControlSpecifier];
		[self reloadSpecifier:refreshControlSpecifier];
	}
}


- (void)check {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil];
}

@end

@interface OREditTextCell : PSEditableTableCell
@end

@implementation OREditTextCell

- (BOOL)textFieldShouldReturn:(id)arg1 {
	return YES;
}

@end