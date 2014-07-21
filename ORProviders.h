#import <UIKit/UIKit.h>
#import <BulletinBoard/BulletinBoard.h>
#import <objc/runtime.h>

@interface OrangeredProviderFactory : NSObject <BBDataProviderFactory>
@end

@interface OrangeredProvider : NSObject <BBRemoteDataProvider> {
	BOOL loaded;
}

@property(nonatomic, retain) NSObject<BBDataProviderFactory> *factory;
@property(nonatomic, retain) NSString *customSectionID;

+ (instancetype)sharedInstance;
- (void)fireAway;

@end
