#import <Preferences/Preferences.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <Twitter/Twitter.h>

#define URL_ENCODE(string) [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)(string), NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8) autorelease]
#define TINT_COLOR [UIColor colorWithRed:232.0/255.0 green:98.0/255.0 blue:49.0/255.0 alpha:1.0];

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

	[UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = TINT_COLOR;
	[UISegmentedControl appearanceWhenContainedIn:self.class, nil].tintColor = TINT_COLOR;

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareTapped:)] autorelease];

	NSDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.insanj.orangered.plist"];
	if (![preferences objectForKey:@"intervalControl"]) {
		PSSpecifier *refreshControlSpecifier = [self specifierForID:@"IntervalControl"];
		[self setPreferenceValue:@(60.0) specifier:refreshControlSpecifier];
		[self reloadSpecifier:refreshControlSpecifier];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	self.view.tintColor = TINT_COLOR;
    self.navigationController.navigationBar.tintColor = TINT_COLOR;

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	self.view.tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}

- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2 {
	PSTableCell *cell = [super tableView:arg1 cellForRowAtIndexPath:arg2];
	if ([cell.title isEqualToString:@"Apply Changes Now"]) {
		cell.textLabel.textColor = TINT_COLOR;
	}

	return cell;
}

- (void)shareTapped:(UIBarButtonItem *)sender {
	NSString *text = @"I love having Reddit in my pocket, thanks to #Orangered by @insanj and @phillipten.";
	NSURL *url = [NSURL URLWithString:@"http://insanj.com/orangered"];

	if (%c(UIActivityViewController)) {
		UIActivityViewController *viewController = [[[%c(UIActivityViewController) alloc] initWithActivityItems:[NSArray arrayWithObjects:text, url, nil] applicationActivities:nil] autorelease];
		[self.navigationController presentViewController:viewController animated:YES completion:NULL];
	}

	else if (%c(TWTweetComposeViewController) && [TWTweetComposeViewController canSendTweet]) {
		TWTweetComposeViewController *viewController = [[[TWTweetComposeViewController alloc] init] autorelease];
		viewController.initialText = text;
		[viewController addURL:url];
		[self.navigationController presentViewController:viewController animated:YES completion:NULL];
	}

	else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/intent/tweet?text=%@%%20%@", URL_ENCODE(text), URL_ENCODE(url.absoluteString)]]];
	}
}

- (void)check {
	[self.view endEditing:YES];
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