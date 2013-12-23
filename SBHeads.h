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