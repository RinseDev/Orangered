#import "ORPrefs.h"
#import "../Orangered.h"
#import <version.h>
#import "Cephei/HBGlobal.h"

void orangeredCheckInterval(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredIntervalNotificationName object:nil];
}

void orangeredSecure(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredSecureNotificationName object:nil];
}

@implementation ORListController

- (id)specifiers {
	if (!_specifiers) {
		_specifiers = [super specifiers];

		TLToneManager *manager = [%c(TLToneManager) sharedToneManager];

		NSMutableArray *indexes = [NSMutableArray array];

		NSArray *toneNames, *toneValues;
		NSMutableArray *installedToneNames, *installedToneValues;

		NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

		for (NSString __strong *key in [manager _alertTonesByIdentifier]) {
			NSString *name = [manager _localizedNameOfToneWithIdentifier:key];
			if (name) {
				[dictionary setObject:name forKey:key];
			}
		}

		if ([dictionary count]) {
			toneValues = [dictionary keysSortedByValueUsingComparator:^(id obj1, id obj2) {
				return [obj1 localizedCaseInsensitiveCompare:obj2];
			}];

			toneNames = [[dictionary allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		}

		dictionary = nil;
		dictionary = [[NSMutableDictionary alloc] init];
		for (id tone in [manager _installedTones]) {
			if (![tone isKindOfClass:%c(TLITunesTone)]) {
				continue;
			}

			if ([tone name] && [tone identifier]) {
				[dictionary setObject:[tone name] forKey:[tone identifier]];
			}
		}

		if ([dictionary count]) {
			installedToneValues = [NSMutableArray arrayWithArray:[dictionary keysSortedByValueUsingComparator:^(id obj1, id obj2) {
				return [obj1 localizedCaseInsensitiveCompare:obj2];
			}]];

			installedToneNames = [NSMutableArray arrayWithArray:[[dictionary allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
		} else {
			installedToneNames = [[NSMutableArray alloc] init];
			installedToneValues = [[NSMutableArray alloc] init];
		}

		[installedToneNames insertObject:@"None" atIndex:0];
		[installedToneValues insertObject:@"<none>" atIndex:0];

		[installedToneNames insertObject:@"" atIndex:0];
		[installedToneValues insertObject:@"<INSTALLED TONES>" atIndex:0];

		[installedToneNames addObject:@""];
		[installedToneValues addObject:@"<ALERT TONES>"];

		[indexes addObject:[NSNumber numberWithInt:([installedToneNames count] - 1)]];
		if (toneNames && [toneNames count] > 0) {
			[indexes addObject:[NSNumber numberWithInt:([toneNames count] + 1)]];

			toneNames = [installedToneNames arrayByAddingObjectsFromArray:toneNames];
			toneValues = [installedToneValues arrayByAddingObjectsFromArray:toneValues];
		} else {
			toneNames = installedToneNames;
			toneValues = installedToneValues;
			[indexes addObject:[NSNumber numberWithInt:1]];
		}

		NSMutableArray *systemToneNames = [[NSMutableArray alloc] init];
		NSMutableArray *systemToneValues = [[NSMutableArray alloc] init];

		[systemToneNames addObject:@""];
		[systemToneValues addObject:@"<RINGTONES>"];

		NSString *tonesDirectory = @"/Library/Ringtones";
		NSFileManager *localFileManager = [[NSFileManager alloc] init];
		NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:tonesDirectory];
		NSString *file;
		while ((file = [dirEnum nextObject])) {
			if ([[file pathExtension] isEqualToString: @"m4r"]) {
				NSString *properToneIdentifier = [NSString stringWithFormat:@"system:%@", [file stringByDeletingPathExtension]];

				[systemToneNames addObject:[file stringByDeletingPathExtension]];
				[systemToneValues addObject:properToneIdentifier];
			}
		}

		if ([systemToneNames count] > 0) {
			[indexes addObject:[NSNumber numberWithInt:[systemToneNames count]]];
		}

		while ([indexes count] < 3) {
			[indexes addObject:[NSNumber numberWithInt:0]];
		}

		self.savedToneValues = [toneValues arrayByAddingObjectsFromArray:systemToneValues];
		self.savedToneTitles = [toneNames arrayByAddingObjectsFromArray:systemToneNames];

		PSSpecifier *soundSpecifier = [self specifierForID:@"SoundPicker"];
		[soundSpecifier setProperty:indexes forKey:@"indexes"];
	}

	return _specifiers;
}

+ (NSString *)hb_specifierPlist {
	return @"ORPrefs";
}

+ (UIColor *)hb_tintColor {
	return kOrangeredTintColor;
}

+ (NSString *)hb_shareText {
	return @"I love having Reddit in my pocket, thanks to #Orangered by github.com/RinseDev/.";
}

+ (NSURL *)hb_shareURL {
	return [NSURL URLWithString:@"http://github.com/RinseDev/Orangered"];
}

- (BOOL)canBeShownFromSuspendedState {
	return NO; 
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

	[self intervalDisable];
	[self updateSoundCellValueLabel];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &orangeredCheckInterval, CFSTR("com.insanj.orangered/Interval"), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &orangeredSecure, CFSTR("com.insanj.orangered/Secure"), NULL, 0);
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(intervalDisable) name:kOrangeredIntervalNotificationName object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(secureTapped) name:kOrangeredSecureNotificationName object:nil];

	[self reloadClientTitlesAndValues];
	[self reloadSpecifiers];

	PSSpecifier *activationSpecifier = [self specifierForID:@"ActivationMethods"];
	[activationSpecifier setProperty:@(NSClassFromString(@"LAActivator") != nil) forKey:@"enabled"];
	[self reloadSpecifier:activationSpecifier];
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
		if (indexPath.row == 1) {	// Credits cell
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
	if (IS_MOST_MODERN) {
		self.navigationController.navigationController.navigationBar.tintColor = nil;
	} else {
		self.navigationController.navigationBar.tintColor = nil;
	}

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
		CGFloat padding = 10.0, savedHeight = 68.0;

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

		NSMutableAttributedString *clickable = [[NSMutableAttributedString alloc] initWithString:@"© 2013-2015 Julian (insanj) Weiss and Rinse Developer Collective. Powered by RedditKit and FDKeychain. Support available in Cydia." attributes:@{ NSFontAttributeName : vanillaFont, NSForegroundColorAttributeName : vanillaColor, NSKernAttributeName : @(0.4) }];

		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"https://twitter.com/insanj"]} range:[clickable.string rangeOfString:@"Julian (insanj) Weiss"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"https://www.github.com/RinseDev"]} range:[clickable.string rangeOfString:@"Rinse Developer Collective"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"https://github.com/samsymons/RedditKit"]} range:[clickable.string rangeOfString:@"RedditKit"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"https://github.com/reidmain/FDKeychain"]} range:[clickable.string rangeOfString:@"FDKeychain"]];
		[clickable setAttributes:@{ NSFontAttributeName : darkFont, NSLinkAttributeName : [NSURL URLWithString:@"http://cydia.saurik.com/package/com.insanj.orangered8/"]} range:[clickable.string rangeOfString:@"Cydia"]];

		_plainTextView.linkTextAttributes = @{ NSForegroundColorAttributeName : darkColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSKernAttributeName : @(0.5) };

		_plainTextView.attributedText = clickable;
		[self addSubview:_plainTextView];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat padding = 10.0, savedHeight = 68.0;
	_plainTextView.frame = CGRectMake(padding, 0.0, self.frame.size.width - (padding * 2.0), savedHeight);
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
