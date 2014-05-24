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
		if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alienblue://"]]) {
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				return ((self.customSectionID = @"com.designshed.alienbluehd"));
			}

			return ((self.customSectionID = @"com.designshed.alienblue"));
		}

		for (NSString *s in CLIENT_LIST) {
			SBApplicationController *controller = (SBApplicationController *)[%c(SBApplicationController) sharedInstance];
			if ([controller applicationWithDisplayIdentifier:s]) {
				return ((self.customSectionID = s));
			}
		}

		return ((self.customSectionID = @"com.apple.mobilesafari"));
	}

	return self.customSectionID;
}

// -(id)sectionIcon;
// -(id)sectionIconData;

- (NSArray *)bulletinsFilteredBy:(NSUInteger)filter count:(NSUInteger)count lastCleared:(NSDate *)lastCleared {
	return nil;
}

- (NSArray *)sortDescriptors {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
}

- (void)pushBulletin:(BBBulletinRequest *)bulletin intoServer:(BBServer *)server {
	//if (!loaded) {
	//	[server _addDataProvider:self forFactory:self.factory];
	//	loaded = YES;
	//}

	// BBDataProviderWithdrawBulletinsWithRecordID(self, @"com.insanj.orangered.bulletin");

	// for (BBBulletinRequest *bulletin in bulletins) {
		BBDataProviderAddBulletin(self, bulletin);
	// }
}

- (void)fireAway {
	/*NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
	BOOL enabled = !preferences[@"enabled"] || [preferences[@"enabled"] boolValue];

	if (!enabled) {
		[sender invalidate];
	}

	CGFloat intervalUnit = preferences[@"intervalControl"] ? [preferences[@"intervalControl"] floatValue] : 60.0;
	NSString *refreshIntervalString = preferences[@"refreshInterval"];
	CGFloat refreshInterval = (refreshIntervalString ? [refreshIntervalString floatValue] : 60.0) * intervalUnit;


	if (fabs(sender.timeInterval - refreshInterval) > 2.0) {
		[sender invalidate];

		NSTimer *orangeredTimer = [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:self selector:@selector(fireAway:) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:orangeredTimer forMode:NSDefaultRunLoopMode];

		NSLog(@"[Orangered] Re-wound timer (%@ -> %@) to ping Reddit every %f seconds.", sender, orangeredTimer, refreshInterval);
	}
*/
	NSLog(@"[Orangered] Sending check message from Timer...");
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
