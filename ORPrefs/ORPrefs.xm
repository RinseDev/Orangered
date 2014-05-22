#import <UIKit/UITableViewCell+Private.h>
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[cell _setDrawsSeparatorAtBottomOfSection:NO];

	if (indexPath.section == [self numberOfSectionsInTableView:tableView] - 1) {
	    cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, cell.bounds.size.width);
	}
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

@interface ORCreditsCell : PSTableCell <UITextViewDelegate> {
	UITextView *_plainTextView;
}
@end

@implementation ORCreditsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.backgroundColor = self.superview.superview.backgroundColor; // UITableView
		CGFloat padding = 10.0, savedHeight = 74.0;

		_plainTextView = [[UITextView alloc] initWithFrame:CGRectMake(padding, 0.0, self.frame.size.width - (padding * 2.0), savedHeight)];

		_plainTextView.backgroundColor = [UIColor clearColor];
		_plainTextView.userInteractionEnabled = YES;
		_plainTextView.scrollEnabled = NO;
		_plainTextView.editable = NO;
		_plainTextView.delegate = self;
	
		UIFont *vanillaFont = [UIFont fontWithName:@".HelveticaNeueInterface-M3" size:13.5];
		UIFont *darkFont = [UIFont fontWithName:@".HelveticaNeueInterface-MediumP4" size:13.5];
		UIColor *vanillaColor = [UIColor colorWithWhite:0.43 alpha:1];
		UIColor *darkColor = [UIColor grayColor];

		NSMutableAttributedString *clickable = [[[NSMutableAttributedString alloc] initWithString:@"© 2013-2014 Julian Weiss, Phillip Tennen. Asset design © 2014 Kyle Paul. Powered by RedditKit and FDKeychain. Support available in Cydia." attributes:@{ NSFontAttributeName : vanillaFont, NSForegroundColorAttributeName : vanillaColor, NSKernAttributeName : @(0.4) }] autorelease];

		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://twitter.com/insanj"]} range:[clickable.string rangeOfString:@"Julian Weiss"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://twitter.com/phillipten"]} range:[clickable.string rangeOfString:@"Phillip Tennen"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://www.twitter.com/"]} range:[clickable.string rangeOfString:@"Kyle Paul"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont,NSLinkAttributeName : [NSURL URLWithString:@"http://twitter.com/insanj"]} range:[clickable.string rangeOfString:@"on Twitter"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont,NSLinkAttributeName : [NSURL URLWithString:@"https://github.com/samsymons/RedditKit"]} range:[clickable.string rangeOfString:@"RedditKit"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont,NSLinkAttributeName : [NSURL URLWithString:@"https://github.com/reidmain/FDKeychain"]} range:[clickable.string rangeOfString:@"FDKeychain"]];

		_plainTextView.linkTextAttributes = @{ NSForegroundColorAttributeName : darkColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSKernAttributeName : @(0.5) };

		_plainTextView.attributedText = clickable;
		[self addSubview:_plainTextView];
	}

	return self;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
	return YES;
}

- (void)dealloc {
	_plainTextView = nil;
	[_plainTextView release];

	[super dealloc];
}

@end