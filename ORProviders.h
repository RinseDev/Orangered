#import <UIKit/UIKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <BulletinBoard/BulletinBoard.h>

@interface OrangeredProviderFactory : NSObject <BBDataProviderFactory>
@end

@interface OrangeredProvider : NSObject <BBRemoteDataProvider>
@property(nonatomic, retain) NSObject<BBDataProviderFactory> *factory;
@property(nonatomic, retain) NSString *customSectionID;

+ (instancetype)sharedInstance;
- (void)pushBulletins:(NSMutableArray *)bulletins;
- (void)fireAway;
@end
