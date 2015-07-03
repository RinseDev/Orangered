#import "ORRingtoneController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <ToneLibrary/ToneLibrary.h>
#import <objc/runtime.h>
#import <UIKit/UITableViewCell+Private.h>

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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = (UITableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
	int idx1 = [[[self specifier] propertyForKey:@"indexes"][0] intValue];
	int idx2 = idx1 + [[[self specifier] propertyForKey:@"indexes"][1] intValue];
	if (indexPath.row == 0 || indexPath.row == idx1 || indexPath.row == idx2) {
		cell.backgroundColor = [UIColor clearColor];

		UIView *labelView = (UIView *)[cell.contentView viewWithTag:(indexPath.row + 26425)];
		if (!labelView) {
			UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 33.5, cell.contentView.frame.size.width, cell.contentView.frame.size.height - 30)];
			label.tag = indexPath.row + 26425;
			label.backgroundColor = [UIColor clearColor];
			label.textColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:1];
			label.font = [UIFont systemFontOfSize:13.0];
			if (indexPath.row == 0) {
				[label setText:@"INSTALLED TONES"];
			} else if (indexPath.row == idx1) {
				[label setText:@"ALERT TONES"];
			} else {
				[label setText:@"RINGTONES"];
			}
			[cell.contentView addSubview:label];
		}

		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.userInteractionEnabled = NO;
	} else {
		cell.backgroundColor = [UIColor whiteColor];
	}

	if ([cell respondsToSelector:@selector(layoutMargins)]) {
		UIEdgeInsets insets = {.left = 45, .right = 0, .top = 0, .bottom = 0};
		cell.layoutMargins = insets;
	}

	return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	int idx1 = [[[self specifier] propertyForKey:@"indexes"][0] intValue];
	int idx2 = idx1 + [[[self specifier] propertyForKey:@"indexes"][1] intValue];

	if (indexPath.row == 0 || indexPath.row == idx1 || indexPath.row == idx2) {
		return 55.5;
	} else {
		return 44;
	}
}

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
