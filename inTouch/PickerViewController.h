#import "Contact.h"

@interface PickerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) Contact *contact;

// UI elements
@property (weak, nonatomic) IBOutlet UIImageView *contactPhotoView;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *remindDateHelpText;
@property (weak, nonatomic) IBOutlet UILabel *remindDate;
@property (weak, nonatomic) IBOutlet UIPickerView *remindDatePickerView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

// Set to the daysBetweenReminder value of current contact. Represents user specified days to wait in between reminders
@property NSUInteger daysBetweenReminder;

@property BOOL shouldHideCancelButton;
@property BOOL postponingContact;
@property BOOL postponingContactFromButton;

@end
