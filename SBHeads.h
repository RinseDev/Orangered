#import <AppSupport/CPDistributedMessagingCenter.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSRootController.h>
#import <Twitter/Twitter.h>
#import <UIKit/UIActivityViewController.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>
#include <stdlib.h>

#import "CydiaSubstrate.h"
#import "BulletinBoard/BulletinBoard.h"

/* ios 7 */
@interface SBUIController
+(id)sharedInstance;
-(void)_deviceLockStateChanged:(id)changed;
@end

@interface SBUIAnimationController
- (void)__startAnimation;
- (int)_animationState;
- (void)_cleanupAnimation;
- (void)_noteAnimationDidCommit:(BOOL)_noteAnimation withDuration:(double)duration afterDelay:(double)delay;
- (void)_noteAnimationDidFail;
- (void)_noteAnimationDidFinish;
- (void)endAnimation;
- (BOOL)isComplete;
@end

@interface SBUIMainScreenAnimationController : SBUIAnimationController
@end

@interface SBUILockscreenSlideAnimationController : SBUIMainScreenAnimationController 
- (void)_finishedSliding;
- (BOOL)_isApplicationLaunchFinished;
- (void)_maybeReportAnimationFinished;
- (void)_prepareAnimation;
- (void)_startAnimation;
@end

/* ios 5-6 */
@interface SpringBoard : UIApplication
-(void)applicationOpenURL:(id)arg1 publicURLsOnly:(BOOL)arg2;
-(void)_relaunchSpringBoardNow;
-(void)relaunchSpringBoard;
@end

@interface SpringBoard (Orangered)
+(id)ORSharedProvider;
@end

@interface SBApplication : NSObject
@end

@interface SBApplicationIcon : NSObject 
-(void)setBadge:(id)arg1;
-(void)launch;
-(id)applicationBundleID;
@end

@interface SBIconModel : NSObject
-(SBApplicationIcon *)applicationIconForDisplayIdentifier:(id)arg1;
@end

@interface SBIconController : NSObject {
	SBIconModel* _iconModel;
}

+(SBIconController *)sharedInstance;
-(SBIconModel *)model;
-(SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayIdentifier; //CLANG SO STUUUUPID
@end

@interface SBApplicationController : NSObject
+(SBApplicationController *)sharedInstance;
-(SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayIdentifier;
-(void)uninstallApplication:(id)arg1;
-(void)removeApplicationsFromModelWithBundleIdentifier:(id)arg1;
-(void)_sendInstalledAppsDidChangeNotification:(id)arg1 removed:(id)arg2 modified:(id)arg3;
@end

@interface UIAlertButton : UIButton
-(id)bodyText;
-(id)title;
@end