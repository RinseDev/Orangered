#import "ORHeaders.h"

#import "ORPuller.h"
#import "ORMessage.h"
#import "ORNotifier.h"
#import "ORProvider.h"
#import "ORLogger.h"

/* Notification Providing and Notifiers */
%hook SpringBoard
%new +(id)ORSharedProvider{ 
 	return [ORProvider sharedProvider];
}

%new +(id)ORSharedNotifier{ 
 	return [ORNotifier sharedNotifier];
}
%end

%hook BBServer
-(void)_loadDataProvidersAndSettings{
	%orig;

	[ORLogger log:@"adding the Orangered notifier to the Notification Center..." fromSource:@"Orangered.xm"];
	[self dpManager:MSHookIvar<BBDataProviderManager *>(self, "_dataProviderManager") addDataProvider:[ORProvider sharedProvider] withSectionInfo:[[ORProvider sharedProvider] defaultSectionInfo]];
}
%end

/* Device Initializations and First Runs */
%hook SBUIController
static BOOL kORUnlocked, kORInitialized;

-(void)_deviceLockStateChanged:(NSNotification *)changed{
	%orig;

	NSNumber *state = changed.userInfo[@"kSBNotificationKeyState"];
	if(!state.boolValue){
		kORUnlocked = YES;

		if(!kORInitialized){
			kORInitialized = YES;
			[ORLogger log:@"started successfully from respring, loading notifier from settings to check unreads..." fromSource:@"Orangered.xm"];
			[[ORNotifier sharedNotifier] grabSeconds];
		}//end if
	}//end if
}//end method
%end

%hook SBUIAnimationController
-(void)endAnimation{
	%orig;

	if(kORUnlocked && ![[NSUserDefaults standardUserDefaults] boolForKey:@"ORDidRun"]){
		kORUnlocked = NO;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ORDidRun"];
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Thanks for installing Orangered! Check Settings to verify your Reddit information, then let Orangered work its magic! You can also adjust how alerts work in the Notifications area." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
	}//end if
}
%end

/* Notification Clearing and Removal Checking */
%hook SBApplicationIcon
-(void)launch{
	%orig;

	if([[self applicationBundleID] isEqualToString:[ORProvider determineHandle]]){
		[ORLogger log:[NSString stringWithFormat:@"detected launch of: %@", [self applicationBundleID]] fromSource:@"Orangered.xm"];
		[[ORProvider sharedProvider] withdrawAndClear];
	}
}//end launch
%end

%hook SBApplicationController
-(void)removeApplicationsFromModelWithBundleIdentifier:(id)arg1{
	if([arg1 isEqualToString:[ORProvider determineHandle]]){
		[ORLogger log:[NSString stringWithFormat:@"detected model removal of: %@", arg1] fromSource:@"Orangered.xm"];
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Detected deletion of primary Reddit client! Please respring to get Orangered back in order.\n(Please ignore if updating the application)" delegate:nil cancelButtonTitle:@"Later" otherButtonTitles:@"Now", nil] show];
	}//end if

	%orig;
}//end remove
%end

%hook UIAlertView
-(void)_buttonClicked:(UIAlertButton *)clicked{
	%orig;

	if([[clicked title] isEqualToString:@"Now"] && ([[self message] rangeOfString:@"Orangered" options:nil].location != NSNotFound)){
		[ORLogger log:@"user sent respring request from UIAlertView!" fromSource:@"Orangered.xm"];
		[[ORProvider sharedProvider] respring];
	}
}//end _buttonClicked
%end