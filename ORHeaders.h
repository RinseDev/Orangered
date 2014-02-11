#import <AppSupport/CPDistributedMessagingCenter.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <Twitter/Twitter.h>
#import <UIKit/UIActivityViewController.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>
#include <stdlib.h>

#import "CydiaSubstrate.h"
#import "NWURLConnection.h"

#define IS_OS_7_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)

@interface BBSectionInfo : NSObject
@property NSUInteger notificationCenterLimit;
@property (nonatomic, retain) NSString *sectionID;

+(id)defaultSectionInfoForType:(NSUInteger)type;
@end

@interface BBSectionIcon : NSObject
@property(copy) NSSet *variants;
-(id)_bestVariantForUIFormat:(int)arg1;
-(id)_bestVariantForFormat:(int)arg1;
-(void)addVariant:(id)arg1;
-(void)setVariants:(NSSet *)arg1;
-(NSSet *)variants;
@end

@interface BBDataProviderIdentity : NSObject
@property(copy) NSString *sectionIdentifier;
@property(copy) BBSectionInfo *defaultSectionInfo;
@property(copy) NSString *sectionDisplayName;
@property(copy) BBSectionIcon *sectionIcon;
@property(copy) NSArray *sortDescriptors;
@property(copy) NSArray *defaultSubsectionInfos;
@property(copy) NSString *sortKey;
@property(copy) NSDictionary *subsectionDisplayNames;
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
-(void)_addDataProvider:(id)arg1 sortSectionsNow:(BOOL)arg2; // not so sure about this
@end

/*
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
-(void)_addDataProvider:(id)arg1 forFactory:(id)arg2;*/

@interface BBAction : NSObject
+(id)actionWithTextReplyCallblock:(id)arg1;
+(id)actionWithLaunchBundleID:(id)arg1 callblock:(id)arg2;
+(id)actionWithLaunchURL:(id)arg1 callblock:(id)arg2;
+(id)actionWithCallblock:(id)arg1;
@end

@interface BBSound : NSObject
@property int soundType;
@property unsigned long systemSoundID;
@property unsigned int soundBehavior;
@property(nonatomic, retain) NSString *ringtoneName;
+(id)alertSoundWithSystemSoundID:(unsigned long)arg1;
-(id)initWithToneAlert:(int)arg1 toneIdentifier:(id)arg2 vibrationIdentifier:(id)arg3;
-(id)initWithToneAlert:(int)arg1;
-(id)initWithRingtone:(id)arg1 vibrationPattern:(id)arg2 repeats:(BOOL)arg3;
@end

@interface BBBulletin : NSObject
@property(nonatomic, retain) BBAction *defaultAction;
@property(readonly) NSString *sectionDisplayName;
@property(readonly) BBSectionIcon *sectionIcon;
@property(readonly) unsigned int messageNumberOfLines;
@property(readonly) NSString *fullUnlockActionLabel;
@property(readonly) NSString *unlockActionLabel;
@property(readonly) unsigned int realertCount;
@property(nonatomic, retain) NSString *bulletinID;
@property(nonatomic, retain) NSString *section;
@property(nonatomic, retain) NSString *sectionID;
@property(nonatomic, retain) NSSet *subsectionIDs;
@property(nonatomic, retain) NSString *recordID;
@property(nonatomic, retain) NSString *publisherBulletinID;
@property(nonatomic, retain) NSString *dismissalID;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain)NSString *subtitle;
@property(nonatomic, retain) NSString *message;
@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) BBSound *sound;
@property(nonatomic, retain) NSDictionary *context;
@property(nonatomic, retain) NSDate *lastInterruptDate;

@property BOOL showsUnreadIndicator;

-(id)init;
@end

@interface BBBulletinRequest : BBBulletin
-(void)generateNewBulletinID;
-(id)publisherMatchID;
-(BOOL)hasContentModificationsRelativeTo:(id)arg1;
-(void)setTentative:(BOOL)arg1;
-(BOOL)showsUnreadIndicator;
-(void)generateBulletinID;
-(void)addAlertSuppressionAppID:(id)arg1;
-(void)setRealertCount:(unsigned int)arg1;
-(unsigned int)realertCount;
-(void)setUnlockActionLabel:(id)arg1;
-(void)withdraw;
-(void)addButton:(id)arg1;
-(void)setPrimaryAttachmentType:(int)arg1;
-(void)setContextValue:(id)arg1 forKey:(id)arg2;
-(void)setShowsUnreadIndicator:(BOOL)arg1;
-(void)publish:(BOOL)arg1;
-(void)addAttachmentOfType:(int)arg1;
-(void)setExpirationEvents:(unsigned int)arg1;
-(unsigned int)expirationEvents;
-(BOOL)tentative;
-(void)publish;
@end

@protocol BBDataProvider <NSObject>

@required
-(NSArray *)bulletinsFilteredBy:(NSUInteger)by count:(NSUInteger)count lastCleared:(NSDate *)cleared;
-(NSString *)sectionIdentifier;
-(NSArray *)sortDescriptors;

@optional
-(BBSectionInfo *)defaultSectionInfo;
-(NSString *)sectionDisplayName;
-(NSArray *)sortDescriptors;

@end

@interface BBServer : NSObject
-(void)_addDataProvider:(id<BBDataProvider>)dataProvider sortSectionsNow:(BOOL)sortSections;
@end

#ifdef __cplusplus
extern "C" {
#endif
	extern void BBDataProviderAddBulletin(id<BBDataProvider> dataProvider, BBBulletinRequest *bulletinRequest);
	extern void BBDataProviderWithdrawBulletinsWithRecordID(id<BBDataProvider> dataProvider, NSString *recordID);
#ifdef __cplusplus
}
#endif

/* ios 7 */
@interface SBUIController
+(id)sharedInstance;
-(void)_deviceLockStateChanged:(id)changed;
@end

@interface SBUIAnimationController
-(void)__startAnimation;
-(int)_animationState;
-(void)_cleanupAnimation;
-(void)_noteAnimationDidCommit:(BOOL)_noteAnimation withDuration:(double)duration afterDelay:(double)delay;
-(void)_noteAnimationDidFail;
-(void)_noteAnimationDidFinish;
-(void)endAnimation;
-(BOOL)isComplete;
@end

@interface SBUIMainScreenAnimationController : SBUIAnimationController
@end

@interface SBUILockscreenSlideAnimationController : SBUIMainScreenAnimationController 
-(void)_finishedSliding;
-(BOOL)_isApplicationLaunchFinished;
-(void)_maybeReportAnimationFinished;
-(void)_prepareAnimation;
-(void)_startAnimation;
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