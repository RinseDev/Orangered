#import "ORRingtoneController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <ToneLibrary/ToneLibrary.h>
#import <objc/runtime.h>

#define kOrangeredTintColor [UIColor colorWithRed:232.0/255.0 green:98.0/255.0 blue:49.0/255.0 alpha:1.0];

@implementation ORRingtoneController

+ (UIColor *)hb_tintColor {
	return kOrangeredTintColor;
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (validSoundID) {
		AudioServicesDisposeSystemSoundID(soundID);
		validSoundID = NO;
	}

	[super viewWillDisappear:animated];
}

/*-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = (UITableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
	int idx1 = [[[self specifier] propertyForKey:@"indexes"][0] intValue];
	int idx2 = idx1 + [[[self specifier] propertyForKey:@"indexes"][1] intValue];
	if (indexPath.row == 0 || indexPath.row == idx1 || indexPath.row == idx2) {
		cell.backgroundColor = kOrangeredTintColor;
	} else {
		cell.backgroundColor = [UIColor whiteColor];
	}

	return cell;
}*/

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (validSoundID) {
		AudioServicesDisposeSystemSoundID(soundID);
		validSoundID = NO;
	}

	UITableViewCell *cell = (UITableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	NSArray *temp = [[[self specifier] titleDictionary] allKeysForObject:cell.textLabel.text];
	NSString *identifier = [temp lastObject];

	if (identifier) {
		TLToneManager *manager = [objc_getClass("TLToneManager") sharedToneManager];
		CFURLRef soundFileURLRef;
		soundFileURLRef = (__bridge CFURLRef)[NSURL URLWithString:[[manager filePathForToneIdentifier:identifier] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];		AudioServicesCreateSystemSoundID(soundFileURLRef, &soundID);

		AudioServicesPlayAlertSound(soundID);
		validSoundID = YES;
	}

	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
