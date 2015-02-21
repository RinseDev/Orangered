#import "ORPrefs.h"

void orangeredCheckInterval(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredIntervalNotificationName object:nil];
}

void orangeredSecure(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredSecureNotificationName object:nil];
}

@implementation ORListController

+ (NSString *)hb_specifierPlist {
	return @"ORPrefs";
}

+ (UIColor *)hb_tintColor {
	return kOrangeredTintColor;
}

+ (NSString *)hb_shareText {
	return @"I love having Reddit in my pocket, thanks to #Orangered by @insanj and @phillipten.";
}

+ (NSURL *)hb_shareURL {
	return [NSURL URLWithString:@"http://insanj.com/orangered"];
}

- (void)loadView {
	[super loadView];

	self.savedClientTitles = [NSArray array];
	self.savedClientValues = [NSArray array];
	self.savedToneTitles = [NSArray array];
	self.savedToneValues = [NSArray array];

	[self table].keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

	[UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = kOrangeredTintColor;
	[UISegmentedControl appearanceWhenContainedIn:self.class, nil].tintColor = kOrangeredTintColor;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.preferences = PREFS;

	if (![self.preferences floatForKey:@"intervalControl" default:0]) {
		PSSpecifier *refreshControlSpecifier = [self specifierForID:@"IntervalControl"];
		[self setPreferenceValue:@(-1.0) specifier:refreshControlSpecifier];
		[self reloadSpecifier:refreshControlSpecifier];
	}

	PSSpecifier *activationSpecifier = [self specifierForID:@"ActivationMethods"];
	[activationSpecifier setProperty:@(NSClassFromString(@"LAActivator") != nil) forKey:@"enabled"];
	[self reloadSpecifier:activationSpecifier];

	[self intervalDisable];
	[self updateSoundCellValueLabel];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[self reloadClientTitlesAndValues];
	[self reloadToneTitlesAndValues];
	[self reloadSpecifiers];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &orangeredCheckInterval, CFSTR("com.insanj.orangered/Interval"), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &orangeredSecure, CFSTR("com.insanj.orangered/Secure"), NULL, 0);
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalDisable) name:kOrangeredIntervalNotificationName object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(secureTapped) name:kOrangeredSecureNotificationName object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, NULL, NULL);
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

- (PSTableCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	PSTableCell *cell = [super tableView:arg1 cellForRowAtIndexPath:arg2];
	if ([cell.title isEqualToString:@"Sound"]) {
		self.soundCell = cell;
		[self updateSoundCellValueLabel];
	}

	else if ([cell.title isEqualToString:@"Apply Changes Now"]) {
		cell.textLabel.textColor = kOrangeredTintColor;
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == [self numberOfSectionsInTableView:tableView] - 1) {
		if (indexPath.row == 0) {	// Apply Changes Now
			cell.separatorInset = UIEdgeInsetsMake(0.0, -15.0, 0.0, 0.0);
		}

		else if (indexPath.row == 1) {	// Credits cell
			[cell _setDrawsSeparatorAtBottomOfSection:NO];
		}
	}
}

- (NSArray *)clientTitles:(id)target {
	return self.savedClientTitles;
}

- (NSArray *)clientValues:(id)target {
	return self.savedClientValues;
}

- (NSArray *)toneTitles:(id)target {
	return self.savedToneTitles;
}

- (NSArray *)toneValues:(id)target {
	return self.savedToneValues;
}

- (BOOL)canBeShownFromSuspendedState {
	return NO; 
}

- (void)reloadToneTitlesAndValues {
	/* Thanks, https://github.com/TUNER88/iOSSystemSoundsLibrary/blob/master/SystemSoundLibrary/SoundListViewController.m
	NSMutableArray *audioFileList = [NSMutableArray array];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *directoryURL = [NSURL URLWithString:@"/System/Library/Audio/UISounds"];
	NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
	
	NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:directoryURL includingPropertiesForKeys:keys options:0 errorHandler:^(NSURL *url, NSError *error) {
		 return YES;
	 }];
	
	for (NSURL *url in enumerator) {
		NSError *error;
		NSNumber *isDirectory = nil;
		if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
			[audioFileList addObject:[url lastPathComponent]];
		}
	}*/

	TLToneManager *toneManager = [%c(TLToneManager) sharedToneManager];
	NSDictionary *savedTones = MSHookIvar<NSDictionary *>(toneManager, "_alertTonesByIdentifier");
	self.savedToneValues = [savedTones allKeys];

	NSMutableArray *localizedTitles = [NSMutableArray arrayWithCapacity:self.savedToneValues.count];
	for (int i = 0; i < self.savedToneValues.count; i++) {
		localizedTitles[i] = [toneManager _localizedNameOfToneWithIdentifier:self.savedToneValues[i]];
	}

	self.savedToneTitles = localizedTitles;
}

- (void)reloadClientTitlesAndValues {
	NSMutableArray *reloadingClientTitles = [NSMutableArray array];
	NSMutableArray *reloadingClientValues = [NSMutableArray array];

	NSDictionary *installedApplicatons = [[ALApplicationList sharedApplicationList] applications]; // identifier : display name
	NSDictionary *supportedClients = CLIENTS;
	
	for (NSString *bundle in [supportedClients allKeys]) {
		if (installedApplicatons[bundle]) {
			[reloadingClientTitles addObject:supportedClients[bundle]];
			[reloadingClientValues addObject:bundle];
		}
	}

	[reloadingClientTitles addObject:@"Safari"];
	[reloadingClientValues addObject:@"com.apple.mobilesafari"];

	if (![self.savedClientTitles isEqualToArray:reloadingClientTitles]) {
		self.savedClientTitles = reloadingClientTitles;
		self.savedClientValues = reloadingClientValues;
	}
}

- (void)updateSoundCellValueLabel {
	if (self.soundCell) {
		NSString *alertToneIdentifier = [self.preferences objectForKey:@"alertTone"];
		NSString *alertToneName = [[%c(TLToneManager) sharedToneManager] _localizedNameOfToneWithIdentifier:alertToneIdentifier];
		self.soundCell.valueLabel.text = alertToneName;
	}
}

- (void)intervalDisable {
	ORLOG(@"Intelligently disabling interval field...");

	CGFloat intervalValue = [self.preferences floatForKey:@"intervalControl" default:0];

	PSSpecifier *refreshIntervalSpecifier = [self specifierForID:@"RefreshInterval"];
	[refreshIntervalSpecifier setProperty:@(intervalValue > 0.0) forKey:@"enabled"];
	[self reloadSpecifier:refreshIntervalSpecifier];

	[[self table] endEditing:YES];
}

- (void)secureTapped {
	PSSpecifier *passwordSpecifier = [self specifierForID:@"PasswordField"];
	[self setPreferenceValue:@"" specifier:passwordSpecifier];
	[self reloadSpecifier:passwordSpecifier];
}

- (void)check {	
	[[self table] endEditing:YES];

	ORLOG(@"Sending check message from Preferences...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredCheckNotificationName object:nil userInfo:@{ @"sender" : @"Preferences" }];
}

- (void)notificationCenter {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredOpenNCNotificationName object:nil];
}

@end

@implementation OREditTextCell

- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	OREditTextCell *editTextCell = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	((UITextField *)[editTextCell textField]).returnKeyType = UIReturnKeyNext;
	return editTextCell;
}

@end

@implementation OREditDoneTextCell

- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	OREditDoneTextCell *editTextCell = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	((UITextField *)[editTextCell textField]).returnKeyType = UIReturnKeyDone;
	return editTextCell;
}

- (BOOL)textFieldShouldReturn:(id)arg1 {
	return YES;
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
	
		UIFont *vanillaFont = [UIFont fontWithName:@".HelveticaNeueInterface-Regular" size:13.5];
		UIFont *darkFont = [UIFont fontWithName:@".HelveticaNeueInterface-MediumP4" size:13.5];
		UIColor *vanillaColor = [UIColor colorWithRed:0.427451 green:0.427451 blue:0.447059 alpha:1.0];
		UIColor *darkColor = [UIColor grayColor];

		NSMutableAttributedString *clickable = [[NSMutableAttributedString alloc] initWithString:@"© 2013-2015 Julian (insanj) Weiss. © 2014 Phillip Tennen, Kyle Paul. Powered by RedditKit and FDKeychain. Support available in Cydia." attributes:@{ NSFontAttributeName : vanillaFont, NSForegroundColorAttributeName : vanillaColor, NSKernAttributeName : @(0.4) }];

		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://twitter.com/insanj"]} range:[clickable.string rangeOfString:@"Julian (insanj) Weiss"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://twitter.com/phillipten"]} range:[clickable.string rangeOfString:@"Phillip Tennen"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://www.twitter.com/"]} range:[clickable.string rangeOfString:@"Kyle Paul"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://twitter.com/insanj"]} range:[clickable.string rangeOfString:@"on Twitter"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"https://github.com/samsymons/RedditKit"]} range:[clickable.string rangeOfString:@"RedditKit"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"https://github.com/reidmain/FDKeychain"]} range:[clickable.string rangeOfString:@"FDKeychain"]];

		_plainTextView.linkTextAttributes = @{ NSForegroundColorAttributeName : darkColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSKernAttributeName : @(0.5) };

		_plainTextView.attributedText = clickable;
		[self addSubview:_plainTextView];
	}

	return self;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
	return YES;
}

- (BOOL)canBeShownFromSuspendedState {
	return NO;
}

@end

@implementation ORClientListItemsController

+ (UIColor *)hb_tintColor {
	return kOrangeredTintColor;
}

@end

%subclass ORRingtoneController : HBListItemsController // RingtonePane, SoundsPrefController

- (void)viewWillAppear:(BOOL)animated {
	self.view.tintColor = kOrangeredTintColor;
	self.navigationController.navigationController.navigationBar.tintColor = kOrangeredTintColor;

	%orig();
}

- (void)viewWillDisappear:(BOOL)animated {
	%orig();

	self.view.tintColor = nil;
	self.navigationController.navigationController.navigationBar.tintColor = nil;
}

%end
