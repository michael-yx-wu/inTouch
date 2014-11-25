#import <UIKit/UIKit.h>

@interface PickerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

// UI elements
@property (weak, nonatomic) IBOutlet UILabel *remindDate;
@property (weak, nonatomic) IBOutlet UIPickerView *remindDatePickerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

// Days passed since last reminder of this contact
@property NSUInteger daysSinceLastReminder;
@property BOOL shouldHideCancelButton;
@property BOOL postponingContact;
@property BOOL postponingContactFromButton;

@end
