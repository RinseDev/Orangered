#import "ORNotifier.h"

@implementation ORNotifier
@synthesize realFireDate;
static ORNotifier *sharedNotifier;
static NSTimer *realTimer;

+(ORNotifier *)sharedNotifier{
	static dispatch_once_t provider_token = 0;
    dispatch_once(&provider_token, ^{
        sharedNotifier = [[self alloc] init];
    });

	return sharedNotifier;
}//end sharedProvider

-(id)init{
	if ((self = [super init])){
		logger = [[ORLogger alloc] initFromSource:@"ORNotifier.m"];
		sharedNotifier = self;

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shoot) name:@"ORPullNotification" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTimer) name:@"ORTimerNotification" object:nil];
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, (void *)resetType, CFSTR("com.insanj.orangered.type"), nil, CFNotificationSuspensionBehaviorCoalesce);
	}//end if

	return self;
}//end init

-(void)grabSeconds{
	if([self getRealFireDate] && ([[self getRealFireDate] timeIntervalSinceNow] > 0.0)){
		realTimer = [NSTimer scheduledTimerWithTimeInterval:ceil([[self getRealFireDate] timeIntervalSinceDate:[NSDate date]]) target:self selector:@selector(fireAndReset:) userInfo:nil repeats:NO];
		[logger log:[NSString stringWithFormat:@"creating from saved timer with fireDate: %@", [realTimer fireDate]]];
	}//end if

	else{
		[self shoot];
		realTimer = [NSTimer scheduledTimerWithTimeInterval:[ORNotifier savedSeconds] target:self selector:@selector(fireAndReset:) userInfo:nil repeats:NO];
		[self setRealFireDate];

		[logger log:[NSString stringWithFormat:@"creating new timer with fireDate: %@ and firing...", [realTimer fireDate]]];
	}//end else
}//end grabSeconds

static void resetType(){
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ORTimerNotification" object:nil];
}


-(void)resetTimer{
	[realTimer invalidate];
	realTimer = nil;

	[self shoot];
	realTimer = [NSTimer scheduledTimerWithTimeInterval:[ORNotifier savedSeconds] target:self selector:@selector(fireAndReset:) userInfo:nil repeats:NO];
	[self setRealFireDate];
}

+(int)savedSeconds{
	BOOL minuteIntervals = [[[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"minuteIntervals"] boolValue];
	NSNumber *intervalText = [[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"intervalText"];

	int seconds = minuteIntervals?([intervalText intValue] * 60):([intervalText intValue] * 60 * 60);                     
	if(!intervalText || seconds == 0)
		seconds = 1 * 60 * 60;

	return seconds;
}//end savedSeconds

-(void)shoot{
	[logger log:@"pulling from servers..."];
	[[[ORPuller alloc] init] run];
}

-(void)fireAndReset:(NSTimer *)sender{
	[logger log:@"fired from saved timer, pushing the responsibility on..."];
	[self shoot];

	realTimer = [NSTimer scheduledTimerWithTimeInterval:[ORNotifier savedSeconds] target:self selector:@selector(fireAndReset:) userInfo:nil repeats:NO];
	[logger log:[NSString stringWithFormat:@"in fireandreset, changing:%@ to:%@", realFireDate, [realTimer fireDate]]];
	[self setRealFireDate];
}

-(NSDate *)getRealFireDate{
	return [[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangeredprefs.plist"]] objectForKey:@"fireDate"];
}

-(void)setRealFireDate{
	[logger log:[NSString stringWithFormat:@"-setRealFireDate is taking:%@ and making it:%@", realFireDate, [realTimer fireDate]]];
	realFireDate = [realTimer fireDate];
	NSMutableDictionary *mutableSettings = [[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangeredprefs.plist"]] mutableCopy];
	if(!mutableSettings)
		mutableSettings = [[NSMutableDictionary alloc] init];

	[mutableSettings setObject:realFireDate forKey:@"fireDate"]; 
	[mutableSettings writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangeredprefs.plist"] atomically:YES];
}//end set

-(void)dealloc{
	[self setRealFireDate];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}
@end