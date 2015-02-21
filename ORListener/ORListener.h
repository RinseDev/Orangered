#import <UIKit/UIKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <libactivator/libactivator.h>

#define ORLOG(fmt, ...) NSLog((@"[Orangered] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
// #define ORLOG(fmt, ...) 

@interface ORListener : NSObject <LAListener>

@end
