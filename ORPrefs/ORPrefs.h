#import "../Orangered.h"
#import <Preferences/Preferences.h>
#import <MobileInstallation/MobileInstallation.h>


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