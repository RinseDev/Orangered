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
#import "NWURLConnection.h"

@interface BBSectionInfo : NSObject
@end

@interface BBSectionIcon : NSObject
@property(copy) NSSet *variants;
-(id)_bestVariantForUIFormat:(int)arg1;
-(id)_bestVariantForFormat:(int)arg1;
-(void)addVariant:(id)arg1;
-(void)setVariants:(id)arg1;
-(id)variants;
@end

@interface BBDataProviderIdentity : NSObject
@property(copy) NSString * sectionIdentifier;
@property(copy) BBSectionInfo * defaultSectionInfo;
@property(copy) NSString * sectionDisplayName;
@property(copy) BBSectionIcon * sectionIcon;
@property(copy) NSArray * sortDescriptors;
@property(retain) BBSectionParameters * sectionParameters;
@property(copy) NSArray * defaultSubsectionInfos;
@property(copy) NSString * sortKey;
@property(copy) NSDictionary * subsectionDisplayNames;
@property(readonly) BOOL syncsBulletinDismissal;
@end

@interface BBDataProviderManager : NSObject
-(id)dataProviders;
-(void)reloadIdentityForSectionID:(id)arg1 withCompletion:(id)arg2;
-(void)dataProviderConnection:(id)arg1 connectionStateDidChange:(BOOL)arg2;
-(void)dataProviderConnection:(id)arg1 removeDataProviderWithSectionID:(id)arg2;
-(void)dataProviderConnection:(id)arg1 addDataProviderWithSectionID:(id)arg2;
-(void)dataProviderOperational:(id)arg1;
-(void)_addDataProvider:(id)arg1 forFactory:(id)arg2 factoryInfo:(id)arg3;
@end

@interface BBServer : NSObject{
	BBDataProviderManager *_dataProviderManager;
}

-(id)init;
+(void)initialize;
-(void)dpManager:(id)arg1 removeDataProviderSectionID:(id)arg2;
-(void)dpManager:(id)arg1 addDataProviderFactory:(id)arg2 withSectionInfo:(id)arg3;
-(void)dpManager:(id)arg1 addDataProvider:(id)arg2 withSectionInfo:(id)arg3;
-(id)dpManager:(id)arg1 sectionInfoForSectionID:(id)arg2;
-(void)_loadDataProvidersAndSettings;
-(void)_removeDataProvider:(id)arg1 forFactory:(id)arg2;
-(void)_addDataProvider:(id)arg1 forFactory:(id)arg2;
@end

@interface BBSound : NSObject
@property int soundType;
@property unsigned long systemSoundID;
@property unsigned int soundBehavior;
@property(copy) NSString * ringtoneName;
- (id)initWithToneAlert:(int)arg1 toneIdentifier:(id)arg2 vibrationIdentifier:(id)arg3;
- (id)initWithToneAlert:(int)arg1;
- (id)initWithRingtone:(id)arg1 vibrationPattern:(id)arg2 repeats:(BOOL)arg3;
@end

@interface BBBulletin : NSObject
@property(readonly) NSString *sectionDisplayName;
@property(readonly) BBSectionIcon *sectionIcon;
@property(readonly) unsigned int messageNumberOfLines;
@property(readonly) NSString *fullUnlockActionLabel;
@property(readonly) NSString *unlockActionLabel;
@property(readonly) unsigned int realertCount;
@property(copy) NSString *bulletinID;
@property(copy) NSString *section;
@property(copy) NSString *sectionID;
@property(copy) NSSet *subsectionIDs;
@property(copy) NSString *recordID;
@property(copy) NSString *publisherBulletinID;
@property(copy) NSString *dismissalID;
@property(copy) NSString *title;
@property(copy) NSString *subtitle;
@property(copy) NSString *message;
@property(retain) NSDate *date;
@property(retain) BBSound *sound;

-(id)init;
-(void)setObservers:(id)arg1;
-(void)setContent:(id)arg1;
-(void)setActions:(id)arg1;
-(void)setContext:(id)arg1;
-(void)setTitle:(id)arg1;
-(void)setSection:(id)arg1;
-(void)setMessage:(id)arg1;
-(void)setSubtitle:(id)arg1;
-(void)setDate:(id)arg1;
-(void)setRecordID:(id)arg1;
-(void)setBulletinID:(id)arg1;
-(void)setSectionID:(id)arg1;
-(void)setSound:(id)arg1;
-(void)setUnlockActionLabelOverride:(id)arg1;
@end

@interface BBBulletinRequest : BBBulletin
- (void)generateNewBulletinID;
- (id)publisherMatchID;
- (BOOL)hasContentModificationsRelativeTo:(id)arg1;
- (void)setTentative:(BOOL)arg1;
- (BOOL)showsUnreadIndicator;
- (void)generateBulletinID;
- (void)addAlertSuppressionAppID:(id)arg1;
- (void)setRealertCount:(unsigned int)arg1;
- (unsigned int)realertCount;
- (void)setUnlockActionLabel:(id)arg1;
- (void)withdraw;
- (void)addButton:(id)arg1;
- (void)setPrimaryAttachmentType:(int)arg1;
- (void)setContextValue:(id)arg1 forKey:(id)arg2;
- (void)setShowsUnreadIndicator:(BOOL)arg1;
- (void)publish:(BOOL)arg1;
- (void)addAttachmentOfType:(int)arg1;
- (void)setExpirationEvents:(unsigned int)arg1;
- (unsigned int)expirationEvents;
- (BOOL)tentative;
- (void)publish;
@end

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