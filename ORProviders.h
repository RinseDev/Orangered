#import <UIKit/UIKit.h>
#import <BulletinBoard/BulletinBoard.h>

@interface OrangeredProviderFactory : NSObject <BBDataProviderFactory>

@end

@interface OrangeredProvider : BBLocalDataProvider <BBDataProvider>

@property (strong, nonatomic) NSObject<BBDataProviderFactory> *factory;

@property (strong, nonatomic) NSString *customSectionID;

+ (instancetype)sharedInstance;

- (void)fireAway;

@end
