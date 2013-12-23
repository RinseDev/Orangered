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

/*
@interface BBSectionInfo : NSObject
@property(assign, nonatomic) unsigned pushSettings;
@property(assign, nonatomic) unsigned notificationCenterLimit;
+(id)defaultSectionInfoForType:(unsigned)type;
-(id)_pushSettingsDescription;
@end

@interface BBServer : NSObject
-(id)_defaultSectionInfoForDataProvider:(id)dataProvider;
-(void)settingsGateway:(id)gateway setSectionInfo:(id)info forSectionID:(id)sectionID;
-(void)settingsGateway:(id)gateway setOrderedSectionIDs:(id)ids;
-(void)settingsGateway:(id)gateway setSectionOrderRule:(unsigned)rule;
-(void)settingsGateway:(id)gateway getSectionInfoWithHandler:(id)handler;
@end*/
