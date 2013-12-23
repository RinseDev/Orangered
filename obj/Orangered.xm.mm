#line 1 "Orangered.xm"



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




#include <logos/logos.h>
#include <substrate.h>
@class UIAlertView; @class SBApplicationController; @class SBApplicationIcon; @class SBAwayController; @class BBServer; @class SBUIController; @class SpringBoard; 
static id _logos_meta_method$_ungrouped$SpringBoard$ORSharedProvider(Class, SEL); static id _logos_meta_method$_ungrouped$SpringBoard$ORSharedNotifier(Class, SEL); static id (*_logos_orig$_ungrouped$SBAwayController$awayView)(SBAwayController*, SEL); static id _logos_method$_ungrouped$SBAwayController$awayView(SBAwayController*, SEL); static void (*_logos_orig$_ungrouped$BBServer$_loadAllDataProviderPluginBundles)(BBServer*, SEL); static void _logos_method$_ungrouped$BBServer$_loadAllDataProviderPluginBundles(BBServer*, SEL); static void (*_logos_orig$_ungrouped$SBUIController$finishedUnscattering)(SBUIController*, SEL); static void _logos_method$_ungrouped$SBUIController$finishedUnscattering(SBUIController*, SEL); static void (*_logos_orig$_ungrouped$SBApplicationIcon$launch)(SBApplicationIcon*, SEL); static void _logos_method$_ungrouped$SBApplicationIcon$launch(SBApplicationIcon*, SEL); static void (*_logos_orig$_ungrouped$SBApplicationController$removeApplicationsFromModelWithBundleIdentifier$)(SBApplicationController*, SEL, id); static void _logos_method$_ungrouped$SBApplicationController$removeApplicationsFromModelWithBundleIdentifier$(SBApplicationController*, SEL, id); static void (*_logos_orig$_ungrouped$UIAlertView$_buttonClicked$)(UIAlertView*, SEL, UIAlertButton *); static void _logos_method$_ungrouped$UIAlertView$_buttonClicked$(UIAlertView*, SEL, UIAlertButton *); 

#line 22 "Orangered.xm"

 static id _logos_meta_method$_ungrouped$SpringBoard$ORSharedProvider(Class self, SEL _cmd){ 
 	return [ORProvider sharedProvider];
}

 static id _logos_meta_method$_ungrouped$SpringBoard$ORSharedNotifier(Class self, SEL _cmd){ 
 	return [ORNotifier sharedNotifier];
}






static BOOL isInitialized = NO;

static id _logos_method$_ungrouped$SBAwayController$awayView(SBAwayController* self, SEL _cmd) {
	if(!isInitialized){
		isInitialized = YES;
		[ORLogger log:@"started successfully from respring, loading notifier from settings to check unreads..." fromSource:@"Orangered.xm"];
		[[ORNotifier sharedNotifier] grabSeconds];
	}

	return _logos_orig$_ungrouped$SBAwayController$awayView(self, _cmd);
}





static void _logos_method$_ungrouped$BBServer$_loadAllDataProviderPluginBundles(BBServer* self, SEL _cmd){
	_logos_orig$_ungrouped$BBServer$_loadAllDataProviderPluginBundles(self, _cmd);

	[ORLogger log:@"adding the Orangered notifier to the Notification Center..." fromSource:@"Orangered.xm"];
	[self _addDataProvider:[ORProvider sharedProvider] sortSectionsNow:YES];
}






static void _logos_method$_ungrouped$SBUIController$finishedUnscattering(SBUIController* self, SEL _cmd){
	_logos_orig$_ungrouped$SBUIController$finishedUnscattering(self, _cmd);

	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ORNotFirstRun"]){
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Thanks for purchasing Orangered! Check the Settings to set your Reddit information, then let Orangered work its magic! You can also adjust how alerts work in the Notifications area." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ORNotFirstRun"];
	}
}





static void _logos_method$_ungrouped$SBApplicationIcon$launch(SBApplicationIcon* self, SEL _cmd){
	_logos_orig$_ungrouped$SBApplicationIcon$launch(self, _cmd);

	if([[self applicationBundleID] isEqualToString:[ORProvider determineHandle]]){
		[ORLogger log:[NSString stringWithFormat:@"detected launch of: %@", [self applicationBundleID]] fromSource:@"Orangered.xm"];
		[[ORProvider sharedProvider] withdrawAndClear];
	}
}






static void _logos_method$_ungrouped$SBApplicationController$removeApplicationsFromModelWithBundleIdentifier$(SBApplicationController* self, SEL _cmd, id arg1){

	if([arg1 isEqualToString:[ORProvider determineHandle]]){
		[ORLogger log:[NSString stringWithFormat:@"detected model removal of: %@", arg1] fromSource:@"Orangered.xm"];
		[[[UIAlertView alloc] initWithTitle:@"Orangered" message:@"Detected deletion of primary Reddit client! Please respring to get Orangered back in order.\n(Please ignore if updating the application)" delegate:nil cancelButtonTitle:@"Later" otherButtonTitles:@"Now", nil] show];
	}

	_logos_orig$_ungrouped$SBApplicationController$removeApplicationsFromModelWithBundleIdentifier$(self, _cmd, arg1);
}







static void _logos_method$_ungrouped$UIAlertView$_buttonClicked$(UIAlertView* self, SEL _cmd, UIAlertButton * clicked){
	_logos_orig$_ungrouped$UIAlertView$_buttonClicked$(self, _cmd, clicked);

	if([[clicked title] isEqualToString:@"Now"] && ([[self bodyText] rangeOfString:@"Orangered" options:nil].location != NSNotFound)){
		[ORLogger log:@"user sent respring request from UIAlertView!" fromSource:@"Orangered.xm"];
		[[ORProvider sharedProvider] respring];
	}
}

static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); Class _logos_metaclass$_ungrouped$SpringBoard = object_getClass(_logos_class$_ungrouped$SpringBoard); { char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_metaclass$_ungrouped$SpringBoard, @selector(ORSharedProvider), (IMP)&_logos_meta_method$_ungrouped$SpringBoard$ORSharedProvider, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_metaclass$_ungrouped$SpringBoard, @selector(ORSharedNotifier), (IMP)&_logos_meta_method$_ungrouped$SpringBoard$ORSharedNotifier, _typeEncoding); }Class _logos_class$_ungrouped$SBAwayController = objc_getClass("SBAwayController"); MSHookMessageEx(_logos_class$_ungrouped$SBAwayController, @selector(awayView), (IMP)&_logos_method$_ungrouped$SBAwayController$awayView, (IMP*)&_logos_orig$_ungrouped$SBAwayController$awayView);Class _logos_class$_ungrouped$BBServer = objc_getClass("BBServer"); MSHookMessageEx(_logos_class$_ungrouped$BBServer, @selector(_loadAllDataProviderPluginBundles), (IMP)&_logos_method$_ungrouped$BBServer$_loadAllDataProviderPluginBundles, (IMP*)&_logos_orig$_ungrouped$BBServer$_loadAllDataProviderPluginBundles);Class _logos_class$_ungrouped$SBUIController = objc_getClass("SBUIController"); MSHookMessageEx(_logos_class$_ungrouped$SBUIController, @selector(finishedUnscattering), (IMP)&_logos_method$_ungrouped$SBUIController$finishedUnscattering, (IMP*)&_logos_orig$_ungrouped$SBUIController$finishedUnscattering);Class _logos_class$_ungrouped$SBApplicationIcon = objc_getClass("SBApplicationIcon"); MSHookMessageEx(_logos_class$_ungrouped$SBApplicationIcon, @selector(launch), (IMP)&_logos_method$_ungrouped$SBApplicationIcon$launch, (IMP*)&_logos_orig$_ungrouped$SBApplicationIcon$launch);Class _logos_class$_ungrouped$SBApplicationController = objc_getClass("SBApplicationController"); MSHookMessageEx(_logos_class$_ungrouped$SBApplicationController, @selector(removeApplicationsFromModelWithBundleIdentifier:), (IMP)&_logos_method$_ungrouped$SBApplicationController$removeApplicationsFromModelWithBundleIdentifier$, (IMP*)&_logos_orig$_ungrouped$SBApplicationController$removeApplicationsFromModelWithBundleIdentifier$);Class _logos_class$_ungrouped$UIAlertView = objc_getClass("UIAlertView"); MSHookMessageEx(_logos_class$_ungrouped$UIAlertView, @selector(_buttonClicked:), (IMP)&_logos_method$_ungrouped$UIAlertView$_buttonClicked$, (IMP*)&_logos_orig$_ungrouped$UIAlertView$_buttonClicked$);} }
#line 116 "Orangered.xm"
