#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import "BulletinBoard/BulletinBoard.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <stdlib.h>

#import "CydiaSubstrate.h"
#import "ORMessage.h"
#import "ORLogger.h"
#import "SBHeads.h"

@interface ORProvider : NSObject <BBDataProvider> {
	NSArray *messages;
	NSArray *bulletins;
	NSTimer *sender;

	ORLogger *logger;
	BBBulletinRequest *bulletin;

	NSString *handle;
	NSString *name;
}

+(ORProvider *)sharedProvider;

-(id)init;
-(NSString *)sectionIdentifier;
-(NSArray *)sortDescriptors;
-(NSArray *)bulletinsFilteredBy:(unsigned)by count:(unsigned)count lastCleared:(id)cleared;
-(NSString *)sectionDisplayName;
-(BBSectionInfo *)defaultSectionInfo;

-(void)withdrawAndClear;
-(void)resetInfo;
-(void)handleNewNotification:(NSNotification *)notification;
-(NSDictionary *)handleWithMessages:(NSArray *)array;
-(void)handleWithGiven:(NSNotification *)notification;
-(NSDictionary *)handleWithDictionary:(NSDictionary *)dict;
-(void)dataProviderDidLoad;

+(NSString *)determineName;
+(NSString *)determineHandle;
-(void)respring;
-(void)setBadgeTo:(int)num;
-(void)dealloc;
@end
