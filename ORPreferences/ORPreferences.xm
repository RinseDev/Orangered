#import <UIKit/UIActivityViewController.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <Twitter/Twitter.h>

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSRootController.h>
#import <objc/runtime.h>
#import "CydiaSubstrate.h"

#import "../ORLogger.h"
#import "../SBHeads.h"
#import "../ORPuller.h"
#import "../ORProvider.h"

#define IS_RETINA ([UIScreen mainScreen].scale > 1)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface PSViewController : UIViewController
-(id)initForContentSize:(CGSize)contentSize;
-(void)setPreferenceValue:(id)value specifier:(id)specifier;
@end

@interface PSListController : PSViewController{
	NSArray *_specifiers;
}

-(void)loadView;
-(void)reloadSpecifier:(PSSpecifier*)specifier animated:(BOOL)animated;
-(void)reloadSpecifier:(PSSpecifier*)specifier;
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
-(PSSpecifier*)specifierForID:(NSString*)specifierID;
@end

@interface PSTableCell : UITableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
@end

@interface ORPreferencesListController: PSListController <UIAlertViewDelegate> {
	ORLogger *logger;
}

-(void)shareTapped:(UIBarButtonItem *)sender;
@end

@implementation ORPreferencesListController
static NSString *prevName, *prevInterval;

-(void)loadView {
	logger = [[ORLogger alloc] initFromSource:@"ORPreferences.xm"];
	UIBarButtonItem *heart = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ORPreferences.bundle/heart.png"] style:UIBarButtonItemStylePlain target:self action:@selector(shareTapped:)];
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0.0);
	UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	[heart setBackgroundImage:blank forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	self.navigationItem.rightBarButtonItem = heart;

	prevName = [[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"usernameText"];
	[super loadView];
}

-(void)shareTapped:(UIBarButtonItem *)sender {
	NSString *text = @"I'll never miss a Reddit message again with #Orangered by @insanj! ";
	NSString *urlString = @"http://insanj.com/orangered/";
	NSURL *url = [NSURL URLWithString:urlString];

	if (%c(TWTweetComposeViewController) && [TWTweetComposeViewController canSendTweet]) {
		TWTweetComposeViewController *viewController = [[TWTweetComposeViewController alloc] init];
		viewController.initialText = text;
		[viewController addURL:url];
		[self.navigationController presentViewController:viewController animated:YES completion:NULL];
	}

	else if (%c(UIActivityViewController)) {
		UIActivityViewController *viewController = [[%c(UIActivityViewController) alloc] initWithActivityItems:[NSArray arrayWithObjects:text, url, nil] applicationActivities:nil];
		[self.navigationController presentViewController:viewController animated:YES completion:NULL];
	}

	else {
		text = [text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/intent/tweet?text=%@%@", text, urlString]]];
	}
}//end sharetapped

-(id)specifiers {

	if(!_specifiers)
		_specifiers = [self loadSpecifiersFromPlistName:[[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/libactivator.list"]?@"ORPreferences":@"ORAntiPreferences" target:self];

	return _specifiers;
}//end specifiers

-(void)save{
	[self.view endEditing:YES];
	[logger log:@"checking inbox from Settings..."];

	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ORNotFirstSave"]){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"If you haven't already, make sure to enable Badges and Sounds in the Notification settings!" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ORNotFirstSave"];
	}

	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]];
	NSString *savedName = [settings objectForKey:@"usernameText"];
	NSString *savedPass = [settings objectForKey:@"passwordText"];
	NSString *savedInterval = [settings objectForKey:@"intervalText"];

	if (!savedName || [savedName isEmpty] || !savedPass || [savedPass isEmpty]){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"You need a valid Reddit username and password to use Orangered!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
		return;
	}//end if not user/pass

	else if(![prevName isEqualToString:savedName] && ![prevName isEmpty]){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Sorry, you need to respring to switch users in this release!" delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Now", nil] show];
		return;
	}

	if([savedInterval floatValue] < 1 && savedInterval){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"The interval you attempted to set was invalid. Make sure it's not below 1, and only contains numbers!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
		PSSpecifier* intervalSpecifier = [self specifierForID:@"NumberField"];
		[self setPreferenceValue:prevInterval specifier:intervalSpecifier];
		[self reloadSpecifier:intervalSpecifier animated:YES];
		[[NSUserDefaults standardUserDefaults] synchronize];
		return;
	}//end if interval not set

	else if(![prevInterval isEqualToString:savedInterval] && savedInterval)
		prevInterval = savedInterval;

	NSDictionary *sentDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Orangered", @"title", @"checking for new messages...", @"message", @"wait", @"label", [NSNumber numberWithBool:YES], @"show", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ORGivenNotification" object:nil userInfo:sentDictionary];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ORTimerNotification" object:nil];
}//end save

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex == 1)
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ORRespringNotification" object:nil];
}

-(void)twitter:(PSSpecifier *)specifier{
	NSString *label = [specifier.properties objectForKey:@"label"];
	NSString *_user = [label substringFromIndex:1];

	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:_user]]];

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:_user]]];

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:_user]]];

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:_user]]];

	else 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:_user]]];
}//end twitter

-(void)mail{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:me%40insanj.com?subject=Orangered%20(1.0)%20Support"]];//
}

-(void)debugView{

	[logger log:@"you found my crazy fucking idea! not putting that in yet..."];
	/*if(logger.debugView){
		[logger log:@"removing crazy idea..."];
		[logger removeView];
	}

	else{
		[logger log:@"creating crazy fucking debug view idea..."];
		[logger createView];
	}*/
}

@end

@interface PeriwinkleCell : PSTableCell {
	NSString *label;
	UIButton *button;

	NSTimer *downTimer;
	BOOL down;
}

-(void)reactToHold;
-(void)buttonTapped;
-(void)falsify;
-(void)touchDown;
@end

@implementation PeriwinkleCell
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.backgroundView = [[UIView alloc] init];
		self.textLabel.hidden = YES;

		button = [[UIButton alloc] init];

		downTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reactToHold) userInfo:nil repeats:YES];
		[button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
		[button addTarget:self action:@selector(falsify) forControlEvents:UIControlEventTouchUpOutside];
		[button addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];

		label = [specifier.properties objectForKey:@"label"];
		[button setTitle:label forState:UIControlStateNormal];

		[button setTitleColor:[UIColor colorWithRed:76.f / 255.f green:86.f / 255.f blue:108.f / 255.f alpha:1] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithRed:56.f / 255.f green:66.f / 255.f blue:88.f / 255.f alpha:1] forState:UIControlStateHighlighted];
		[button setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.5f] forState:UIControlStateNormal];
		
		button.titleLabel.textAlignment = UITextAlignmentCenter;
		button.titleLabel.font = [UIFont systemFontOfSize:15];
		button.titleLabel.shadowOffset = CGSizeMake(0, 1);
		button.backgroundColor = [UIColor clearColor];
		button.autoresizingMask = UIViewAutoresizingFlexibleWidth;

		CGRect buttonFrame = button.frame;
		buttonFrame.size.width = self.contentView.frame.size.width;
		buttonFrame.size.height = self.contentView.frame.size.height;
		button.frame = buttonFrame;
		
		[button setCenter:CGPointMake(button.center.x, button.center.y - 25)];
		[self.contentView addSubview:button];
	}//end if

	return self;
}//end init

-(void)reactToHold{
    if (down){
    	SystemSoundID ORRYEAH;
		CFURLRef cfurl = (CFURLRef)CFBridgingRetain([[NSBundle bundleWithPath:@"/Library/PreferenceBundles/ORPreferences.bundle"] URLForResource:@"ORRYEAH" withExtension:@"aiff"]);
		AudioServicesCreateSystemSoundID(cfurl, &ORRYEAH);
		AudioServicesPlaySystemSound(ORRYEAH);
    }
}//end reactToHold

-(void)touchDown{
	down = TRUE;
}

-(void)falsify{
	down = FALSE;
}

-(void)buttonTapped {
	down = FALSE;
	NSString *fun = @"Team Periwinkle for life!";

	if([[button.titleLabel text] isEqualToString:fun])
		[button setTitle:label forState:UIControlStateNormal];
	
	else
		[button setTitle:fun forState:UIControlStateNormal];
}//end buttontapped

-(float)preferredHeightForWidth:(float)width {
	return [button.titleLabel.text sizeWithFont:button.titleLabel.font].height;
}
@end

@interface RequestCell : PSTableCell {
	NSString *label;
	UIButton *button;
}
@end

@implementation RequestCell
-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.backgroundView = [[UIView alloc] init];
		self.textLabel.hidden = YES;

		button = [[UIButton alloc] init];
		[button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];

		label = [specifier.properties objectForKey:@"label"];
		[button setTitle:label forState:UIControlStateNormal];

		[button setTitleColor:[UIColor colorWithRed:76.f / 255.f green:86.f / 255.f blue:108.f / 255.f alpha:1] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor colorWithRed:56.f / 255.f green:66.f / 255.f blue:88.f / 255.f alpha:1] forState:UIControlStateHighlighted];
		[button setTitleShadowColor:[UIColor colorWithWhite:1 alpha:1.0f] forState:UIControlStateNormal];
		
		button.titleLabel.textAlignment = UITextAlignmentCenter;
		button.titleLabel.font = [UIFont systemFontOfSize:15];
		button.titleLabel.shadowOffset = CGSizeMake(0, 1);
		button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
		button.backgroundColor = [UIColor clearColor];
		button.autoresizingMask = UIViewAutoresizingFlexibleWidth;

		CGRect buttonFrame = button.frame;
		buttonFrame.size.width = self.contentView.frame.size.width;
		buttonFrame.size.height = self.contentView.frame.size.height + 20;
		button.frame = buttonFrame;

		[self.contentView addSubview:button];
	}//end if

	return self;
}//end init

-(void)buttonTapped {
	[button setTitle:@"Thanks! I'll make sure to get back to you soon, but feel free check up on me via Twitter :)" forState:UIControlStateNormal];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:me%40insanj.com?subject=Orangered%20(1.0)%20Request!&body=%0A%0A%3C3"]];
	});
}//end buttontapped

-(float)preferredHeightForWidth:(float)width {
	return [button.titleLabel.text sizeWithFont:button.titleLabel.font].height + 100;
}
@end

@interface ORAboutListController : PSListController
-(void)twitter:(PSSpecifier *)specifier;
@end

@implementation ORAboutListController

- (id)specifiers {
	if(!_specifiers)
		_specifiers = [self loadSpecifiersFromPlistName:@"ORAbout" target:self];

	return _specifiers;
}//end specifiers

-(void)twitter:(PSSpecifier *)specifier{
	NSString *label = [specifier.properties objectForKey:@"label"];
	NSString *user = [label substringFromIndex:1];

	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];

	else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];

	else 
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];
}//end twitter

@end

@interface ORGroupedCell : PSTableCell {
	UIImageView *imageView;
}
@end

@implementation ORGroupedCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		NSString *location = [specifier propertyForKey:@"location"];

		if(!location)
			return self;

		//sets three-high image
		if([location characterAtIndex:0] == '3') {
			imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ORPreferences.bundle/triple.png"]];
							
			if([location characterAtIndex:1] == 't')
				[imageView setCenter:CGPointMake(32.5, imageView.center.y - 0.5)];
			
			else if([location characterAtIndex:1] == 'm')
				[imageView setCenter:CGPointMake(32.5, (imageView.center.y - 0.5) - 45)];
			
			else
				[imageView setCenter:CGPointMake(32.5, (imageView.center.y + 0.5) - 90)];
		}//end if

		//sets two-high image
		else {
			imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ORPreferences.bundle/double.png"]];
					
			if([location characterAtIndex:1] == 't')
				[imageView setCenter:CGPointMake(32.5, imageView.center.y - 0.5)];
			
			else
				[imageView setCenter:CGPointMake(32.5, (imageView.center.y - 0.5) - (imageView.frame.size.height / (IS_RETINA?2:4)))];
		}//end else

		if(!IS_RETINA)
			[imageView setFrame:CGRectMake(imageView.frame.origin.x + 21.5, imageView.frame.origin.y, imageView.frame.size.width / 2, imageView.frame.size.height /2)];

		if(IS_IPAD)
			[imageView setFrame:CGRectMake(imageView.frame.origin.x + 21.5, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height)];

		[self addSubview:imageView];
	}//end if

	return self;
}//end init
@end


@interface ORHelpListController : PSListController
@end

@implementation ORHelpListController

- (id)specifiers {
	if(!_specifiers){
		_specifiers = [self loadSpecifiersFromPlistName:IS_IPAD?@"ORiPadHelp":@"ORHelp" target:self];
	}

	return _specifiers;
}//end specifiers

@end


@interface ORHelpCell : PSTableCell
@end

@implementation ORHelpCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if(self){
		self.textLabel.numberOfLines = 0;
	    self.textLabel.font = [UIFont systemFontOfSize:16.f];
	    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
   	}

   	return self;
}//end init

@end

