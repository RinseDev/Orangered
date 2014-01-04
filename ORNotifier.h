#import "SBHeads.h"
#import "ORPuller.h"
#import "ORLogger.h"

@interface ORNotifier : NSObject {
	ORLogger *logger;
}

@property (retain, nonatomic) ORPuller *puller;
@property (retain, nonatomic) NSDate *realFireDate;

+(ORNotifier *)sharedNotifier;
-(id)init;
-(void)grabSeconds;

-(void)resetTimer;
+(int)savedSeconds;

-(void)shoot;
-(void)fireAndReset:(NSTimer *)sender;

-(NSDate *)realFireDate;
-(void)setRealFireDate;
-(void)dealloc;
@end