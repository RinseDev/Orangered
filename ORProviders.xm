#import "ORProviders.h"

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
	return [[[self sectionIdentifier] componentsSeparatedByString:@"."] lastObject];
}

- (BBSectionInfo *)defaultSectionInfo {
	BBSectionInfo *sectionInfo = [BBSectionInfo defaultSectionInfoForType:0];
	sectionInfo.notificationCenterLimit = 10;
	sectionInfo.sectionID = [self sectionIdentifier];
	return sectionInfo;
}

- (id)sectionIdentifier {
	if (!self.customSectionID) {
		for (NSString *s in [CLIENT_LIST allKeys]) {
			SBApplicationController *controller = (SBApplicationController *)[%c(SBApplicationController) sharedInstance];
			if ([controller applicationWithDisplayIdentifier:s]) {
				return ((self.customSectionID = s));
			}
		}

		return ((self.customSectionID = @"com.apple.mobilesafari"));
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
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"Orangered.Check" object:nil];
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
