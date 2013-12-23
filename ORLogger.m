#import "ORLogger.h"

@implementation ORLogger
@synthesize debugView, debugTextView;
static BOOL debug;

+(BOOL)log:(NSString *)string fromSource:(NSString *)string2{

	BOOL should = [[[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"debugOn"] boolValue];
	if(should)
		NSLog(@"Orangered: [%@] %@", string2, string);

	return should;
}

-(ORLogger *)initFromSource:(NSString *)string{

	if((self = [super init])){
		source = string;
		debug = [[[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"debugOn"] boolValue];
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, (void *)resetDebug, CFSTR("com.insanj.orangered.debug"), nil, CFNotificationSuspensionBehaviorCoalesce);
	}

	return self;
}//end initf/source

static UIAlertView *alerty;
static void resetDebug(){
	debug = [[[NSDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.insanj.orangered.plist"]] objectForKey:@"debugOn"] boolValue];
	[ORLogger log:[NSString stringWithFormat:@"turning %@ debug logs, according to user request", debug?@"on":@"off"] fromSource:@"ORLogger.m"];
	
	if(debug && !alerty.visible){
			alerty = [[UIAlertView alloc] initWithTitle:@"Orangered" message:@"To access your Debug Logs, make sure you have the Cydia package \"syslogd to /var/log/syslog\" installed, and go to: /var/log/syslog (in iFile or likewise program). Send the entire log to me if there's a problem!" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alerty show];
	}//end if
}


-(void)log:(NSString *)string{
	NSString *formatted = [NSString stringWithFormat:@"Orangered: [%@] %@", source, string];
	if(debug)
		NSLog(@"%@", formatted);
	if(debugView)
		[debugTextView setText:[NSString stringWithFormat:@"%@\n%@", [debugTextView text], formatted]];
}

-(UIView *)createView{
	[self log:@"adding?"];
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window)
  	  window = [[UIApplication sharedApplication].windows objectAtIndex:0];

	CGRect frame = window.frame;
	frame.size.height = frame.size.height / 2;
	frame.origin.y += window.center.y;
	debugView = [[UIView alloc] initWithFrame:frame];
	debugView.backgroundColor = [UIColor blackColor];

	debugTextView = [[UITextView alloc] initWithFrame:frame];
	debugView.backgroundColor = [UIColor whiteColor];
	[debugView addSubview:debugTextView];

	[window addSubview:debugView];
	return debugView;
}

-(void)removeView{
	[self log:@"removing?"];
	[debugView removeFromSuperview];
	debugView = nil;
}

@end

@implementation NSString (Orangered)
- (BOOL)isEmpty {
   if([self length] == 0)
       return YES;

   if(![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
       return YES;

   return NO;
}
@end