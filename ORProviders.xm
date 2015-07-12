#import "ORProviders.h"
#import "Orangered.h"

@implementation OrangeredProvider

+ (instancetype)sharedInstance {
	static OrangeredProvider *sharedInstance;

	static dispatch_once_t provider_token = 0;
	dispatch_once(&provider_token, ^{
		sharedInstance = [[self alloc] init];
		sharedInstance.factory = [[OrangeredProviderFactory alloc] init];
	});

	return sharedInstance;
}

- (NSString *)sectionDisplayName {
	return @"Orangered";
}

- (BBSectionIcon *)sectionIcon {
	if (!self.customSectionIcon) {
		BBSectionIconVariant *iconVariant = [BBSectionIconVariant variantWithFormat:0 imagePath:@"/Library/PreferenceBundles/ORPrefs.bundle/modern.png"];
		self.customSectionIcon = [[BBSectionIcon alloc] init];
		[self.customSectionIcon addVariant:iconVariant];
	}

	return self.customSectionIcon;
}

- (BBSectionInfo *)defaultSectionInfo {
	BBSectionInfo *sectionInfo = [BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit = 10;
	sectionInfo.sectionID = [self sectionIdentifier];

	sectionInfo.allowsNotifications = YES;
	sectionInfo.showsInNotificationCenter = YES;
	sectionInfo.showsInLockScreen = YES;
	sectionInfo.alertType = 1;
	sectionInfo.pushSettings = 63;

	return sectionInfo;
}

- (id)sectionIdentifier {
	if (!self.customSectionID) {
		return ((self.customSectionID = @"com.insanj.orangered"));
	}

	return self.customSectionID;
}

- (NSArray *)bulletinsFilteredBy:(NSUInteger)filter count:(NSUInteger)count lastCleared:(NSDate *)lastCleared {
	return nil;
}

- (NSArray *)sortDescriptors {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}

- (void)fireAway {
	ORLOG(@"[Orangered] Sending check message from Timer...");
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:kOrangeredCheckNotificationName object:nil userInfo:@{ @"sender" : @"Timer" }];
}

@end

@implementation OrangeredProviderFactory

- (id)dataProviders {
	return @[[OrangeredProvider sharedInstance]];
}

- (NSString *)sectionDisplayName {
	return [[self dataProviders][0] sectionDisplayName];
}

- (BBSectionInfo *)defaultSectionInfo {
	return [[self dataProviders][0] defaultSectionInfo];
}

- (id)sectionIdentifier {
	return [[self dataProviders][0] sectionIdentifier];
}

- (NSArray *)bulletinsFilteredBy:(NSUInteger)filter count:(NSUInteger)count lastCleared:(NSDate *)lastCleared {
	return [[self dataProviders][0] bulletinsFilteredBy:filter count:count lastCleared:lastCleared];
}

- (NSArray *)sortDescriptors {
	return [[self dataProviders][0] sortDescriptors];
}

@end
