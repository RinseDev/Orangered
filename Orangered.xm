//Orangered 1.1
//Created by Julian Weiss

#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Foundation/Foundation.h>
#import "BulletinBoard/BulletinBoard.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <stdlib.h>

#import "CydiaSubstrate.h"
#import "ORPuller.h"
#import "ORMessage.h"
#import "ORNotifier.h"
#import "ORProvider.h"
#import "ORLogger.h"
#import "SBHeads.h"


//Creates a sharedProvider (GCD) for the ORProvider (what handles sending notifications).
//This allows the currently living instance of ORProvider to be accessed from any class/process.
%hook SpringBoard
%new +(id)ORSharedProvider{ 
 	return [ORProvider sharedProvider];
}

%new +(id)ORSharedNotifier{ 
 	return [ORNotifier sharedNotifier];
}
%end

//Called when the devices recovers from a respring, safe mode, or boot-- when the LS is initializing.
//Dispatches the creation of an ORNotifier, which manages when to check for messages/notify user.
//Waits 15 seconds to prevent annoyances with booting times/network connectivity (could be better).
%hook SBAwayController
static BOOL isInitialized = NO;

-(id)awayView {
	if(!isInitialized){
		isInitialized = YES;
		[ORLogger log:@"started successfully from respring, loading notifier from settings to check unreads..." fromSource:@"Orangered.xm"];
		[[ORNotifier sharedNotifier] grabSeconds];
	}//end if

	return %orig;
}//end awayView
%end

//Adds the ORProvider (a BBDataProvider) to the central list of all BBDataProviders, allowing it
//to send messages and communicate with BulletinBoard/the Notification Center.
%hook BBServer
-(void)_loadAllDataProviderPluginBundles{
	%orig;

	[ORLogger log:@"adding the Orangered notifier to the Notification Center..." fromSource:@"Orangered.xm"];
	[self _addDataProvider:[ORProvider sharedProvider] sortSectionsNow:YES];
}//end _loadAll
%end

//Called when the device is returning to the homescreen-- checks to see if the user has run
//the tweak before, and if not, sends them the welcome popup. Should be changes to use the
//com.insanj.orangeredprefs.plist in the future (NSUD unrecommended).
%hook SBUIController
-(void)finishedUnscattering{
	%orig;

	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ORNotFirstRun"]){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Thanks for purchasing Orangered! Check the Settings to set your Reddit information, then let Orangered work its magic! You can also adjust how alerts work in the Notifications area." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ORNotFirstRun"];
	}
}//end finishedUnscattering
%end

//Called when an app launched. Checks to see if the launched app was our current Reddit
//client, and if so, clears the badge (which would have been set by the Provider.)
%hook SBApplicationIcon
-(void)launch{
	%orig;

	if([[self applicationBundleID] isEqualToString:[ORProvider determineHandle]]){
		[ORLogger log:[NSString stringWithFormat:@"detected launch of: %@", [self applicationBundleID]] fromSource:@"Orangered.xm"];
		[[ORProvider sharedProvider] withdrawAndClear];
	}
}//end launch
%end

//Tells the user that when deleting an app that it'll screw up everything (used to try -resetInfo, but):
//SpringBoard[9399]: *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[__NSArrayM insertObject:atIndex:]: object cannot be nil'
%hook SBApplicationController

- (void)removeApplicationsFromModelWithBundleIdentifier:(id)arg1{

	if([arg1 isEqualToString:[ORProvider determineHandle]]){
		[ORLogger log:[NSString stringWithFormat:@"detected model removal of: %@", arg1] fromSource:@"Orangered.xm"];
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Detected deletion of primary Reddit client! Please respring to get Orangered back in order.\n(Please ignore if updating the application)" delegate:nil cancelButtonTitle:@"Later" otherButtonTitles:@"Now", nil] show];
	}//end if

	%orig;
}//end remove

%end

//Instead of creating my own UIAlertView in a %hook, I just %hook UIAlertView, and if the
//alert in question (when a tapped button) has "Orangered" in it, and the user tapped
//a "Now", respring.
%hook UIAlertView
-(void)_buttonClicked:(UIAlertButton *)clicked{
	%orig;

	if([[clicked title] isEqualToString:@"Now"] && ([[self bodyText] rangeOfString:@"Orangered" options:nil].location != NSNotFound)){
		[ORLogger log:@"user sent respring request from UIAlertView!" fromSource:@"Orangered.xm"];
		[[ORProvider sharedProvider] respring];
	}
}//end _buttonClicked
%end