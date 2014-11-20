#import "../Orangered.h"

#import <UIKit/UITableViewCell+Private.h>
#import <UIKit/UIImage+Private.h>
#import <Twitter/Twitter.h>
#import <ToneLibrary/ToneLibrary.h>
#import <MobileInstallation/MobileInstallation.h>
#import <Preferences/Preferences.h>
#import <AppList/AppList.h>

@interface ORListController: PSListController {
	PSTableCell *soundCell;
}

@property(nonatomic, retain) NSMutableArray *savedClientTitles, *savedClientValues;

- (void)reloadClientTitlesAndValues;

@end

@interface OREditTextCell : PSEditableTableCell

@end

@interface OREditDoneTextCell : PSEditableTableCell

@end


@interface ORCreditsCell : PSTableCell <UITextViewDelegate> {
	UITextView *_plainTextView;
}

@end

@interface ORClientListItemsController : PSListItemsController

@end

@interface ORRingtoneController : RingtoneController

@end

@interface ORLinkCell : PSTableCell
@end